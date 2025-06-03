#!/usr/bin/env python3

import argparse
import os
import re
from datetime import datetime, timedelta
from packaging.version import parse as parse_version
from jinja2 import Environment, FileSystemLoader
from itertools import groupby


def parse_changelog(changelog_content):
    """Parse changelog content and extract version information."""
    version_pattern = r'v(\d+\.\d+\.\d+)\s+\((\d{4}-\d{2}-\d{2})\)'
    matches = re.finditer(version_pattern, changelog_content)
    versions = []

    for match in matches:
        version, date_str = match.groups()
        versions.append({
            'version': version,
            'date': datetime.strptime(date_str, '%Y-%m-%d')
        })

    return sorted(versions, key=lambda x: parse_version(x['version']), reverse=True)


def get_latest_patch_versions(versions):
    """Group versions by major.minor and keep only the latest patch version."""
    def get_major_minor(version):
        return '.'.join(version['version'].split('.')[:2])

    # Sort versions by major.minor and then by patch level
    versions.sort(key=lambda x: (get_major_minor(x), parse_version(x['version'])),
                  reverse=True)

    # Group by major.minor and take only the first (latest) patch version
    latest_versions = []
    for _, group in groupby(versions, key=get_major_minor):
        latest_versions.append(next(group))

    return latest_versions


def get_supported_releases(versions, current_date):
    """
    Determine supported versions based on the rules:
    - A release becomes EOL when there are three newer (major/minor) versions
    - But earliest four weeks after it has been released
    """
    supported = []
    major_minor_versions = []

    # Get only latest patch versions
    latest_versions = get_latest_patch_versions(versions)

    for ver in latest_versions:
        major_minor = '.'.join(ver['version'].split('.')[:2])
        if major_minor not in major_minor_versions:
            major_minor_versions.append(major_minor)

    for ver in latest_versions:
        release_date = ver['date']
        four_weeks_passed = (current_date - release_date) > timedelta(weeks=4)
        major_minor = '.'.join(ver['version'].split('.')[:2])
        newer_major_minor_versions = len([
            v for v in major_minor_versions
            if parse_version(v) > parse_version(major_minor)
        ])

        if newer_major_minor_versions < 3 or not four_weeks_passed:
            supported.append({
                'number': f"v{ver['version']}",
                'date': ver['date'].strftime('%Y-%m-%d'),
                'eol': (release_date + timedelta(weeks=4)).strftime('%Y-%m-%d')
                if newer_major_minor_versions >= 3 else None
            })

    return supported


def generate_doc_from_template(versions, template_path, output_path):
    """Generate documentation using Jinja2 template."""
    env = Environment(
        loader=FileSystemLoader(os.path.dirname(template_path)),
        trim_blocks=True,
        lstrip_blocks=True
    )

    template_name = os.path.basename(template_path)
    template = env.get_template(template_name)

    content = template.render(versions=versions)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, 'w') as f:
        f.write(content)


def main():
    parser = argparse.ArgumentParser(
        description="Generate supported versions documentation"
    )
    parser.add_argument(
        "--changelog", default="CHANGELOG.rst",
        help="Path to changelog file"
    )
    parser.add_argument(
        "--template", default="docs/supported_releases_template.jinja",
        help="Path to Jinja template file"
    )
    parser.add_argument(
        "--output", default="docs/supported_releases.rst",
        help="Output file path"
    )

    args = parser.parse_args()

    with open(args.changelog, 'r') as f:
        changelog_content = f.read()

    versions = parse_changelog(changelog_content)

    current_date = datetime.now()
    supported_releases = get_supported_releases(versions, current_date)

    generate_doc_from_template(supported_releases, args.template, args.output)

    print(f"Generated supported versions documentation at {args.output}")


if __name__ == "__main__":
    main()
