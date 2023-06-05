#!/usr/bin/python3

# This tool fixes a broken apt-cacher-ng cache.
#
# Just run it like: `python3 fix-acng-cache2.py` in the /var/cache/apt-cacher-ng
# directory.
#
# apt-cacher-ng sometimes leaves incomplete files in its cache, which
# will cause 503 errors, when the cache data is then used in offline
# mode. This script fixes this by downloading all Packages lists an
# (In)Release files afresh.
#
# apt-cacher-ng should be stopped while fixing the cache and should
# not be started without being in offline mode afterwards (as this may
# break the cache again).

import argparse
import hashlib
import http.client
import pathlib
import re
import shutil
import urllib.parse
import urllib.request

# compression libraries for reading compressed indices
import lzma
import bz2
import gzip

import yaml

ap = argparse.ArgumentParser()
ap.add_argument('dir', nargs='?', default=pathlib.Path('.'), type=pathlib.Path)
ap.add_argument('--version-pins', type=argparse.FileType("r"))
ap.add_argument('--delete-blacklist', action='append', default=[], type=pathlib.Path)

args = ap.parse_args()

if args.version_pins:
    version_pins = yaml.safe_load(args.version_pins)
else:
    version_pins = {}


def read_head_file(fname):
    with open(fname, "rb") as f:
        f.readline()  # chop off the status line
        return http.client.parse_headers(f)


def expect(iterator, line_pattern):
    line = next(iterator)
    if not re.match(line_pattern, line):
        raise Exception("Invalid InRelease file")


def filter_pgp_signed_message(f):
    expect(f, r"-----BEGIN PGP SIGNED MESSAGE-----$")
    expect(f, r"Hash:")
    expect(f, r"$")
    for line in f:
        if re.match(r"-----BEGIN PGP SIGNATURE-----$", line):
            break

        yield line
    else:
        raise Exception("Incomplete PGP signed message")


def head_file_path(path):
    return path.parent / (path.name + '.head')


def parse_inrelease(dist):
    release_path = dist / "Release"
    head_file = head_file_path(release_path)
    extra_download = []
    if head_file.exists():
        filter_ = lambda x: x  # noqa
        extra_download = ["Release.gpg"]
    else:
        release_path = dist / "InRelease"
        if head_file_path(release_path).exists():
            filter_ = filter_pgp_signed_message
        else:
            raise Exception("No Release.head or InRelease.head file in dist:", dist)

    print("Refreshing (In)Release file ...", dist)
    release_url = read_head_file(head_file_path(release_path))['X-Original-Source']
    download(release_path, release_url)
    for extra in extra_download:
        download(release_path.parent / extra,
                 urllib.parse.urljoin(release_url, extra))

    with release_path.open("r") as f:
        cur_header = None
        res = {}

        for line in filter_(f):
            if not line.strip():
                continue

            if line[0].isspace():
                res[cur_header].append(line)
                continue

            hdr, value = line.split(":", 1)
            if not value.strip():
                cur_header = hdr
                res[hdr] = []
            else:
                res[hdr] = value.strip()
    return res, release_url


def validate_file(path, size, hash_):
    if path.stat().st_size != size:
        return False

    with path.open("rb") as f:
        hasher = hashlib.sha256()
        while True:
            chunk = f.read(1024)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest() == hash_


def serialize_headers(path, status, items):
    with path.open("w") as f:
        f.write(status + "\r\n")
        for k, v in items.items():
            f.write("{}: {}\r\n".format(k, v))
        f.write("\r\n")


def download(path, url, by_hash=None):
    print("download", path, url, by_hash)

    if by_hash is not None:
        by_hash_file = path.parent / "by-hash/SHA256" / by_hash
        by_hash_url = urllib.parse.urljoin(url, "by-hash/SHA256/" + by_hash)
        conn = download(by_hash_file, by_hash_url)
        # copy the file over
        with by_hash_file.open("rb") as src:
            with path.open("wb") as dest:
                shutil.copyfileobj(src, dest)
    else:
        with urllib.request.urlopen(url) as conn:
            if conn.status != 200:
                print("Error retrieving the file from the original source.")
            with path.open("wb") as f:
                shutil.copyfileobj(conn, f)

    serialize_headers(head_file_path(path), "HTTP/1.1 200 OK", {
        "Content-Length": conn.headers["Content-Length"],
        "Last-Modified": conn.headers["Last-Modified"],
        "X-Original-Source": url,
    })

    return conn


def is_implied_file(path_cache, path, relpath):
    if not path.parent.exists():
        return False

    for prefix in ['Packages', 'Translations-en', 'Translations-de']:
        if relpath.stem == prefix:
            return path_cache[relpath.parent / relpath.stem][0] == relpath

    return False


def suffix_order(path):
    try:
        return ['.xz', '.gz', ''].index(path.suffix)
    except ValueError:
        return float('inf')


def update_packages(package_file, base_path, base_url):
    opener = {
        '': open,
        '.xz': lzma.open,
        '.gz': gzip.open,
        '.bz2': bz2.open,
        }[package_file.suffix]

    caches = {}

    def handle_file(meta):
        if meta["Filename"].startswith("."):
            # handle the weirdness of the mellanox repo
            cached_file = package_file.parent / meta["Filename"]
            url = urllib.parse.urljoin(base_url, meta["Filename"])
        else:
            # paths are relative to the repo root, which is above the
            # `dists` directory
            cached_file = base_path / meta["Filename"]
            url = urllib.parse.urljoin(
                base_url,
                str(pathlib.Path("../..") / meta["Filename"])
            )

        pool_dirs_alive_files.setdefault(cached_file.parent, set()). \
            add(cached_file.name)

        if cached_file.exists():
            if not validate_file(cached_file, int(meta["Size"], 10), meta["SHA256"]):
                print("file failed to validate", cached_file)
                download(cached_file, url)
            return

        if cached_file.parent in caches:
            cache = caches[cached_file.parent]
        else:
            cache = {}
            for entry in cached_file.parent.glob("*.deb"):
                cache.setdefault(entry.parent / entry.stem.split("_")[0], []). \
                    append(cached_file)
            caches[cached_file.parent] = cache

        pkg_name = cached_file.stem.split("_")[0]
        if cached_file.parent / pkg_name in cache:
            if pkg_name in version_pins:
                pkg_version = cached_file.stem.split("_")[1]
                if pkg_version in version_pins[pkg_name]:
                    download(cached_file, url)
            else:
                download(cached_file, url)

    # NOTE the "rt" must not be changed to "r": for the compressed
    # readers the "t" is not implied like for files!
    with opener(package_file, "rt") as f:
        cur = {}
        prev_k = None
        for line in f:
            if not line.strip():
                handle_file(cur)
                cur = {}
                continue

            if line[0].isspace():
                cur[prev_k] += line
                continue

            k, v = line.split(":", 1)
            v = v.strip()
            cur[k] = v
            prev_k = k
        if cur:
            handle_file(cur)


# This variable tracks all files in the package pools that are
# referenced by a Package list. We guess the pool directories based
# on the paths of the packages.
pool_dirs_alive_files = {}

for repo in args.dir.iterdir():
    if repo.name.startswith("_") or not repo.is_dir():
        # filter out the special underscore prefixed dirs and non-dirs
        # in the top-level cache directory
        continue

    # apt-cacher-ng places an InRelease.head in every dist-cache (even
    # those that use Release file instead so we use this to find the
    # dist-caches in the filesystem forest!
    for dist in repo.glob("**/InRelease.head"):
        dist = dist.parent
        res, base_url = parse_inrelease(dist)

        by_hash = res.get("Acquire-By-Hash", "no").strip().lower() == "yes"

        path_cache = {}
        for entry in res["SHA256"]:
            _, _, relpath = entry.split()
            relpath = pathlib.Path(relpath)
            path_cache.setdefault(relpath.parent / relpath.stem, []).append(relpath)

        for entry in path_cache.values():
            entry.sort(key=suffix_order)

        for entry in res["SHA256"]:
            hash_, size, relpath = entry.split()
            size = int(size, base=10)

            entry_file = dist / relpath
            entry_url = urllib.parse.urljoin(base_url, relpath)

            if dist not in entry_file.parents:
                raise Exception("Entry points outside of the dist – malicious repo?")

            if entry_file.stem in ['Release', 'InRelease']:
                # some repos include the hash of the Release /
                # InRelease file in ther file list, no need to check
                # it again!
                continue

            if entry_file.exists():
                if not validate_file(entry_file, size, hash_):
                    download(entry_file, entry_url, by_hash=hash_ if by_hash else None)
                    print("refresh", entry_file)

            elif is_implied_file(path_cache, entry_file, pathlib.Path(relpath)):
                download(entry_file, entry_url, by_hash=hash_ if by_hash else None)
                print("download missing", entry_file)

            if entry_file.exists() and entry_file.stem == 'Packages':
                # the dist.parent.parent is pure guessery ...
                # we should find a better way to enumerate the repos correctly
                update_packages(entry_file, dist.parent.parent, base_url)

for pool_dir, alive in pool_dirs_alive_files.items():
    if any(parent in args.delete_blacklist
           for parent in pool_dir.parents):
        continue
    if not pool_dir.exists():
        continue
    for entry in pool_dir.iterdir():
        if entry.suffix == '.head':
            continue
        if entry.name not in alive:
            print("Deleting unreferenced file", entry)
            entry.unlink()

    for entry in pool_dir.iterdir():
        if entry.suffix == '.head':
            if not (entry.parent / entry.stem).exists():
                print("Deleting dangling .head file", entry)
                entry.unlink()
