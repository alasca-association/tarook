#!/usr/bin/python3
"""Tool for compiling a helm chart mirror.

It is called as
```
$ python3 compile_helm_mirror.py config.yaml mirror_dir
```
The `mirror_dir` can then be served via http and contains subdirectories
that are valid helm chart repos.

Example config file:
```
# trailing slashes are extremely important – python url joining is weird!
repos:
  hashicorp: "https://helm.releases.hashicorp.com/"
  yaook.cloud: "https://charts.yaook.cloud/operator/stable/"

charts:
- hashicorp/vault 0.23.0
- yaook.cloud/etcdbackup
```

If there is no version given for a chart the latest non-prerelease
version is chosen. (Better loose version selection is a nice-to-have
for the future). If a version is given, exactly that version is added
to the mirror.

Requirements:
- semver

"""


import argparse
import contextlib
import datetime
import hashlib
import os
import shutil
import sys
import typing
import urllib.request

import semver
import yaml

from dataclasses import dataclass
from urllib.parse import urljoin


@dataclass
class Repo:
    name: str
    url: str
    index: typing.Any
    res_index: typing.Any


@contextlib.contextmanager
def urlopen(url):
    # the https://charts.jetstack.io/ repo returns 403 if we don't
    # fake the user-agent
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as conn:
        yield conn


def report_warning(message, *args, **kwargs):
    print("Warning:", message.format(*args, **kwargs), file=sys.stderr)


def report_error(message, *args, **kwargs):
    global ok
    print("Error:", message.format(*args, **kwargs), file=sys.stderr)
    ok = False


def validate_chart(chart_path, info, set_missing_digest=False):
    if not os.path.exists(chart_path):
        return False

    if not info["digest"]:
        report_warning("No digest for {} to validate", chart_path)
        if not set_missing_digest:
            return True

    with open(chart_path, "rb") as f:
        hasher = hashlib.sha256()
        while True:
            chunk = f.read(1024)
            if not chunk:
                break
            hasher.update(chunk)

    if not info["digest"] and set_missing_digest:
        info["digest"] = hasher.hexdigest()
        return True
    else:
        return hasher.hexdigest() == info["digest"]


ap = argparse.ArgumentParser()

ap.add_argument("config")
ap.add_argument("target_dir")

args = ap.parse_args()


# fix the configuration of yaml, the timestamps generated by default
# can't be read by go-yaml – yay for standards!
def represent_datetime(dumper, value):
    return dumper.represent_scalar('tag:yaml.org,2002:timestamp', value.isoformat())


yaml.add_representer(
    datetime.datetime,
    represent_datetime,
    yaml.SafeDumper,
)

with open(args.config) as f:
    config = yaml.safe_load(f)

ok = True

# Load the repo indices, having a cache would be nice they are big!
# (but difficult because not all repos provide useful info on HEAD)
repos = {}
for repo, url in config["repos"].items():
    index_url = urljoin(url, "./index.yaml")
    try:
        with urlopen(index_url) as conn:
            index = yaml.safe_load(conn)
    except urllib.error.HTTPError as e:
        report_error("Could not retrive index {}: {}", index_url, e)
        continue

    if index.get("apiVersion") != "v1":
        report_error("Repo {} has unknown chart repo api version {}",
                     repo, index.get("apiVersion"))
        continue

    repos[repo] = Repo(name=repo, url=url, index=index, res_index={})

for chart in config["charts"]:
    try:
        full_ref, version = chart.split()
    except ValueError:
        full_ref = chart
        version = None
    repo_name, ref = full_ref.split("/")

    try:
        repo = repos[repo_name]
    except KeyError:
        report_error("The repo is not configured {}", repo)
        continue

    try:
        chart_versions = repo.index["entries"][ref]
    except KeyError:
        report_error("The chart {} is not in the index (repo: {})", ref, repo_name)
        continue

    selected = None
    for considered in chart_versions:
        # chop off a leading v: seen in the wild, breaks semver.parse
        if considered["version"].startswith("v"):
            considered["version"] = considered["version"][1:]
        try:
            if semver.parse(considered["version"])["prerelease"]:
                # do not select pre-releases, helm refuses to download them as most
                # recent version
                continue
        except ValueError:
            report_warning("Warning: Invalid semver {} in index for {}/{}",
                           considered["version"], repo_name, ref)
            continue

        # should we allow more powerful selectors here?
        # helm seems to use the format 1.x.x for loose matching
        if (selected is None or
            semver.cmp(considered["version"], selected["version"]) == 1):  # noqa
            if version is None or semver.cmp(version, considered["version"]) == 0:
                selected = considered

    if selected is None:
        report_error("No matching version found for {}/{}", repo_name, ref)
        continue

    mangled_selected = dict(selected)
    chart_file_name = "{}-{}.tgz".format(ref, selected["version"])
    mangled_selected["urls"] = [chart_file_name]
    repo.res_index.setdefault(ref, []).append(mangled_selected)

    # download the selected chart
    repo_dir = os.path.join(args.target_dir, repo_name)
    chart_path = os.path.join(repo_dir, chart_file_name)
    os.makedirs(repo_dir, exist_ok=True)

    if validate_chart(chart_path, selected):
        # we already have the file, nothing to do
        continue

    try:
        chart_url = urljoin(repo.url, selected["urls"][0])
        with urlopen(chart_url) as conn:
            with open(chart_path, "wb") as f:
                shutil.copyfileobj(conn, f)
    except urllib.error.HTTPError as e:
        report_error("Donwloading chart {}: {}", chart_file_name, e)
        continue

    if not validate_chart(chart_path, selected, set_missing_digest=True):
        report_error("Downloaded file does not match the digest in the index {}",
                     chart_path)
        continue


for repo_name, repo in repos.items():
    res_index = {}
    res_index["apiVersion"] = "v1"
    res_index["generated"] = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc)
    res_index["entries"] = repo.res_index
    with open(os.path.join(args.target_dir, repo_name, "index.yaml"), "w") as f:
        yaml.safe_dump(res_index, f)

if not ok:
    sys.exit(1)