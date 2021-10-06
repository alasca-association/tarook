#!/usr/bin/python3

"""This script can be used to init or update skeleton of ansible roles.
Ansible role skeleton is initialized or updated based on :param:`action`.

**init**

    Init action creates ansible role skeleton and bootstraps it with data
    defined by script's arguments.
    See `init` action help for details:

    .. code:: bash

        manage_roles.py init --help

    This example creates full ansible role skeleton for role `test-role`
    in `ansible/roles` directory. Full skeleton contains dirs and files
    defined in `FULL_SKELETON` variable.

    .. code:: bash

        manage_roles.py init test-role --path ansible/roles --full

**update**

    Update action merges metadata file (meta/main.yaml) with metadata
    defined by script's arguments and optionally creates missing
    skeleton directory structure.
    - Update is forbidden for already defined metadata key(s).
      This could be forced by `--force` argument. In this case, merge strategy
      `Strategy.REPLACE` is used.
    - If metadata file (meta/main.yaml) doesn't exist then only metadata
      defined by script's arguments are used.
    - Update action (by default) process only ansible meta/main.yaml
      file and others (base) are skipped. This could be jumped by
      `--create-missing` argument, when the rest (base) of the skeleton
      structure is created.
    See `update` action help for details:

    .. code:: bash

        manage_roles.py update --help

    This example updates metadata of ansible role `test-role` in
    `ansible/roles` directory with record `author`.

    .. code:: bash

        manage_roles.py update test-role --path ansible/roles --author XYZ

    This example updates existing ansible role in `ansible/roles` directory
    with missing skeleton structure. Full skeleton (defined in `FULL_SKELETON`
    variable) is applied.

    .. code:: bash

        manage_roles.py update test-role --path ansible/roles \
         --create-missing --full

    This example updates all ansible roles in `ansible/roles` directory
    with record `license`.

    .. code:: bash

        manage_roles.py update '*' --path ansible/roles/ --license Apache-2.0

Doctests:

    .. code:: bash

        python3 -m doctest -v manage_roles.py


This script enhances functionality of `ansible-galaxy init` CLI tool that comes
bundled with ansible.
"""
import json
import pathlib
import re
import sys
import yaml

from jsonschema import (
    validate as jsonschema_validate,
    exceptions as jsonschema_exceptions,
)
from collections import defaultdict
from argparse import ArgumentParser, ArgumentTypeError, Action, ArgumentError
from mergedeep import merge
from loguru import logger
from packaging.version import Version, InvalidVersion

META_GALAXY_KEYS = frozenset(
    {
        "role_name",
        "author",
        "description",
        "company",
        "issue_tracker_url",
        "license",
        "min_ansible_version",
        "min_ansible_container_version",
        "galaxy_tags",
        "platforms",
    }
)
META_KEYS = frozenset({"dependencies"})
PLATFORM_FORMAT = (
    '{"name": "<platform_name>", "versions": ["<platform_version_1>",'
    ' "<platform_version_2>"]}'
)
PLATFORM_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema",
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "versions": {"type": "array"},
    },
    "required": ["name", "versions"],
    "additionalProperties": False,
}


def write_yaml(file, data, sort_keys=False, explicit_start=True):
    # Ensure that parent dir exists, if not create it
    file.parent.mkdir(parents=True, exist_ok=True)
    with open(file, "w") as fd:
        yaml.safe_dump(
            data, fd, sort_keys=sort_keys, explicit_start=explicit_start
        )


def write_file(file, data):
    # Ensure that parent dir exists, if not create it
    file.parent.mkdir(parents=True, exist_ok=True)
    with open(file, "w") as fd:
        fd.writelines(data)


def get_keys(dict_obj):
    """Generates all keys of a nested dictionary.

    Only keys listed in `META_GALAXY_KEYS` and `META_KEYS` are filtered
    """
    for key, value in dict_obj.items():
        if key in META_KEYS or key in META_GALAXY_KEYS:
            yield key
        if isinstance(value, dict):
            for k in get_keys(value):
                if k in META_KEYS or k in META_GALAXY_KEYS:
                    yield k


def bootstrap_base(role, action, filepath, **kwargs):
    """Bootstrap with simple content

    **Init** action creates file and bootstraps it with simple content.

    **Update** action (by default) process only ansible meta/main.yaml
    file and others (base) are skipped. This could be jumped by
    `--create-missing` argument, when the rest (base) of the skeleton
    structure is created.
    """
    if action == "update" and not kwargs["create_missing"]:
        logger.debug(
            f"[{role}] {action} of {filepath.parent.name}/{filepath.name} -"
            " SKIPPED"
        )
        return

    write_file(
        filepath, ["---\n", f"# {filepath.parent.name} file for {role}"]
    )
    logger.debug(
        f"[{role}] {action} of {filepath.parent.name}/{filepath.name} - DONE"
    )


def get_meta(**kwargs):
    """Compose metadata based on provided arguments"""
    meta = defaultdict(dict)
    for key, value in kwargs.items():
        if key in META_GALAXY_KEYS and value is not None:
            meta["galaxy_info"][key] = value

        if key in META_KEYS and value is not None:
            meta[key] = value
    return dict(meta)


def bootstrap_meta(role, action, filepath, **kwargs):
    """Bootstrap metadata

    **Init** action creates metadata file (meta/main.yaml) and bootstraps
    it with metadata defined by script's arguments.

    **Update** action merges metadata file (meta/main.yaml) with metadata
    defined by script's arguments. Update is forbidden for already
    defined metadata key(s). This could be forced by `--force` argument.
    In this case, merge strategy `Strategy.REPLACE` is used. If metadata
    file (meta/main.yaml) doesn't exist then only metadata defined by script's
    arguments are used.
    """
    meta = get_meta(**kwargs)
    if action == "update" and filepath.exists():
        # Read the metadata file
        with open(filepath, "r") as fd:
            data = yaml.safe_load(fd)
        if data:
            # Failed to update if some metadata keys are already there.
            # Could be forced by `--force` argument
            common_keys = set(get_keys(data)).intersection(set(get_keys(meta)))
            if common_keys and not kwargs["force"]:
                logger.error(
                    f"[{role}] {action} of"
                    f" {filepath.parent.name}/{filepath.name} - already"
                    f" defined metadata key(s): {', '.join(common_keys)}, use"
                    " `--force` argument if you want to overwrite them."
                )
                exit(1)
            # Merge metadata file with metadata defined by script's arguments
            # Dummy reverse sort ensures expected order of metadata top level
            # keys: 1. galaxy_info, 2. dependencies
            merged = merge(data, meta)
            meta = dict(sorted(merged.items(), reverse=True))

    write_yaml(filepath, meta)
    logger.debug(
        f"[{role}] {action} of {filepath.parent.name}/{filepath.name} - DONE"
    )


MINIMAL_SKELETON = {
    "meta": {"files": [{"name": "main.yaml", "bootstrap": bootstrap_meta}]},
    "tasks": {"files": [{"name": "main.yaml", "bootstrap": bootstrap_base}]},
    "defaults": {
        "files": [{"name": "main.yaml", "bootstrap": bootstrap_base}]
    },
}
FULL_SKELETON = {
    "handlers": {
        "files": [{"name": "main.yaml", "bootstrap": bootstrap_base}]
    },
    "vars": {"files": [{"name": "main.yaml", "bootstrap": bootstrap_base}]},
    "tests": {"files": [{"name": "test.yaml", "bootstrap": bootstrap_base}]},
    "templates": {"files": []},
    "files": {"files": []},
}
FULL_SKELETON.update(MINIMAL_SKELETON)


def skeleton_manage(role, action, path, full=False, **kwargs):
    """Init or update skeleton of ansible role.

    Ansible role skeleton is initialized or updated based on :param:`action`
    """
    dirs = FULL_SKELETON if full else MINIMAL_SKELETON
    # Init or update role skeleton
    for subdirectory, meta in dirs.items():
        directory = path / role / pathlib.Path(subdirectory)
        for file_meta in meta["files"]:
            file_path = directory / pathlib.Path(file_meta["name"])
            file_meta["bootstrap"](role, action, file_path, **kwargs)
    logger.info(f"[{role}] {action} has been successfully accomplished")


def dir_path(path):
    if pathlib.Path(path).is_dir():
        return pathlib.Path(path)

    raise ArgumentTypeError(f"{path} is not a valid path of directory")


def role_name(arg_value, regex=re.compile(r"^[a-z0-9_]+$")):
    """Check if given role name is valid.

    >>> role_name("role_01")
    'role_01'
    >>> role_name("role-01")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: role-01 is not a valid role name. Role names are limited to ^[a-z0-9_]+$
    >>> role_name("*_=&%$")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: *_=&%$ is not a valid role name. Role names are limited to ^[a-z0-9_]+$
    """  # noqa: E501
    if regex.match(arg_value):
        return arg_value

    raise ArgumentTypeError(
        f"{arg_value} is not a valid role name. Role names are limited to"
        f" {regex.pattern}"
    )


def galaxy_tags(arg_value, regex=re.compile(r"^[A-Za-z0-9]+$")):
    """Check if given galaxy tag is valid.

    >>> galaxy_tags("Tag01")
    'Tag01'
    >>> galaxy_tags("tag X")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: tag X is not a valid galaxy tag. Galaxy tags are limited to ^[A-Za-z0-9]+$
    >>> galaxy_tags("three%")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: three% is not a valid galaxy tag. Galaxy tags are limited to ^[A-Za-z0-9]+$
    """  # noqa: E501
    if regex.match(arg_value):
        return arg_value

    raise ArgumentTypeError(
        f"{arg_value} is not a valid galaxy tag. Galaxy tags are limited to"
        f" {regex.pattern}"
    )


def required_max_length(max_length):
    class RequiredLength(Action):
        def __call__(self, parser, args, values, option_string=None):
            if not len(values) <= max_length:
                raise ArgumentError(
                    self,
                    f"{self.dest} is limited to {max_length} tags per role",
                )

            setattr(args, self.dest, values)

    return RequiredLength


def platforms(arg_value):
    """Check if given platform is valid.

    >>> platforms(PLATFORM_FORMAT)
    {'name': '<platform_name>', 'versions': ['<platform_version_1>', '<platform_version_2>']}
    >>> platforms('{invalid_json}')
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: invalid platform format: {invalid_json}. Expected following: {"name": "<platform_name>", "versions": ["<platform_version_1>", "<platform_version_2>"]}
    >>> platforms('{"name": "<platform_name>"}')
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: invalid platform format: {"name": "<platform_name>"}
    'versions' is a required property
    <BLANKLINE>
    Failed validating 'required' in schema:
        {'$schema': 'http://json-schema.org/draft-07/schema',
         'additionalProperties': False,
         'properties': {'name': {'type': 'string'},
                        'versions': {'type': 'array'}},
         'required': ['name', 'versions'],
         'type': 'object'}
    <BLANKLINE>
    On instance:
        {'name': '<platform_name>'}
    """  # noqa: E501
    try:
        platform = json.loads(arg_value)
    except json.JSONDecodeError:
        raise ArgumentTypeError(
            f"invalid platform format: {arg_value}. Expected following:"
            f" {PLATFORM_FORMAT}"
        )

    try:
        jsonschema_validate(platform, PLATFORM_SCHEMA)
    except jsonschema_exceptions.ValidationError as e:
        raise ArgumentTypeError(f"invalid platform format: {arg_value}\n{e}")

    return platform


def version(arg_value):
    """Check if given version is valid.

    Validates if the given :param:`arg_value` is PEP440
    compliant using :class:`packaging.version.Version`.

    E.g see ansible release history: https://pypi.org/project/ansible/#history

    >>> version("1.0")
    '1.0'
    >>> version("1.4.3")
    '1.4.3'
    >>> version("1.9.0.1")
    '1.9.0.1'
    >>> version("2.5.0b2")
    '2.5.0b2'
    >>> version("2.7.0.dev0")
    '2.7.0.dev0'
    >>> version("2.9.15rc1")
    '2.9.15rc1'
    >>> version("4.0.0a3")
    '4.0.0a3'
    >>> version("4.7.0")
    '4.7.0'
    >>> version("1.2,1.3")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: 1.2,1.3 is not a valid version. Use valid version string.
    >>> version("1.2.x")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: 1.2.x is not a valid version. Use valid version string.
    >>> version("4.x")
    Traceback (most recent call last):
        ...
    argparse.ArgumentTypeError: 4.x is not a valid version. Use valid version string.
    """  # noqa: E501
    try:
        Version(arg_value)
    except InvalidVersion:
        raise ArgumentTypeError(
            f"{arg_value} is not a valid version. Use valid version string."
        )

    return arg_value


def main(role, action, path, **kwargs):
    role_path = path / role

    if action == "init" and role_path.exists():
        logger.error(f"[{role}] {action} - role exists: {role_path}")
        exit(1)

    if action == "update" and not any(kwargs.values()):
        logger.error(f"[{role}] {action} without any value is forbidden")
        exit(1)

    if action == "update" and role == "*":
        roles_paths = [
            [item.name, item.parent]
            for item in path.iterdir()
            if item.is_dir()
        ]
        for role_name, role_path in roles_paths:
            skeleton_manage(role_name, action, role_path, **kwargs)
        exit(0)

    if action == "update" and not role_path.exists():
        logger.error(f"[{role}] {action} - role doesn't exist: {role_path}")
        exit(1)

    skeleton_manage(role, action, path, **kwargs)


if __name__ == "__main__":
    # Parsers
    parser = ArgumentParser()
    parent_parser = ArgumentParser(add_help=False)
    meta_parser = ArgumentParser(add_help=False)
    meta_parser_init = ArgumentParser(add_help=False)
    meta_parser_update = ArgumentParser(add_help=False)
    meta_parser_init._optionals.title = (
        "optional arguments with default values used for metadata"
        " bootstrapping (role init only)"
    )
    meta_parser_update._optionals.title = (
        "optional arguments used for metadata bootstrapping (role update only)"
    )
    meta_parser._optionals.title = (
        "optional arguments used for metadata bootstrapping"
    )
    # Common arguments
    parent_parser.add_argument(
        "--path",
        "-p",
        type=dir_path,
        help=(
            "The path of directory in which the skeleton role will be"
            " initialized or updated."
        ),
        required=True,
    )
    parent_parser.add_argument(
        "--full",
        action="store_true",
        help=(
            "Creates full skeleton directory structure:"
            f" {list(FULL_SKELETON.keys())}"
        ),
    )
    # Metadata common arguments
    meta_parser.add_argument(
        "--role_name",
        type=role_name,
        help=(
            "Overrides the name of the role by record `role_name` in"
            " meta/main.yaml. This argument overrides the **ansible galaxy**"
            " default role name, which  is the unaltered repository name."
            " Bear in mind, that this argument modify the **ansible galaxy**"
            " default behaviour. Role's directory name defines role name for"
            " **local ansible** run and is used in `include_role` or `roles`"
            " ansible modules."
            " Role names are limited to lowercase word characters (a-z, 0-9)"
            " and ‘_’."
        ),
    )
    meta_parser.add_argument("--author", help="Role author")
    meta_parser.add_argument("--description", help="Role description")
    meta_parser.add_argument("--company", help="Role company")
    meta_parser.add_argument(
        "--min_ansible_version",
        type=version,
        help=(
            "Minimum ansible version for ansible role. "
            "Given ansible version should be PEP440 compliant."
        ),
    )
    meta_parser.add_argument(
        "--min_ansible_container_version",
        type=version,
        help=(
            "If this a Container Enabled role, provide the minimum ansible"
            " container version. Given ansible version should be PEP440"
            " compliant."
        ),
    )
    meta_parser.add_argument(
        "--galaxy_tags",
        type=galaxy_tags,
        action=required_max_length(20),
        help=(
            "Role galaxy tags. A tag is a keyword that describes and"
            " categorizes the role. Users find roles by searching for tags. A"
            " tag is limited to a single word comprised of alphanumeric"
            " characters. Multiple galaxy tags can be given. Maximum 20 tags"
            " per role."
        ),
        nargs="+",
    )
    meta_parser.add_argument(
        "--platforms",
        type=platforms,
        help=(
            "Supported platform and list of its valid versions in format: "
            f" {PLATFORM_FORMAT}. Multiple platforms can be given."
        ),
        nargs="+",
    )
    # Metadata init arguments
    meta_parser_init.add_argument(
        "--license",
        help="Role license. Defaults to %(default)s",
        default="Apache-2.0",
    )
    meta_parser_init.add_argument(
        "--issue_tracker_url",
        help=(
            "Issue tracker url. If the issue tracker for your role is not on"
            " github. Defaults to %(default)s"
        ),
        default="https://gitlab.com/yaook/k8s/-/issues",
    )
    meta_parser_init.add_argument(
        "--dependencies",
        help=(
            "Role dependencies. Multiple dependencies can be given. Defaults"
            " to %(default)s"
        ),
        nargs="+",
        default=[],
    )
    # Metadata update arguments
    meta_parser_update.add_argument("--license", help="Role license")
    meta_parser_update.add_argument(
        "--issue_tracker_url",
        help=(
            "Issue tracker url. If the issue tracker for your role is not on"
            " github"
        ),
    )
    meta_parser_update.add_argument(
        "--dependencies",
        help="Role dependencies. Multiple dependencies can be given.",
        nargs="+",
    )
    meta_parser_update.add_argument(
        "--create-missing",
        help="Force creating of missing skeleton directory structure.",
        action="store_true",
    )
    # Subparsers
    subparsers = parser.add_subparsers(
        help="Desired action to perform", dest="action", required=True
    )
    subparser_init = subparsers.add_parser(
        "init",
        parents=[parent_parser, meta_parser, meta_parser_init],
        help="Initialize the skeleton for a new ansible role",
    )
    subparser_update = subparsers.add_parser(
        "update",
        parents=[parent_parser, meta_parser, meta_parser_update],
        help=(
            "Update the existing ansible role. This action only updates"
            " the meta/main.yaml of the existing ansible role."
            " If you want to create missing skeleton directory structure use"
            " `--create-missing` argument."
        ),
    )
    # Subparsers arguments
    subparser_init.add_argument("role", help="Role name to be initialized")
    subparser_update.add_argument(
        "role",
        help=(
            "Role name to be updated. An asterisk `'*'` can be used for"
            " updating all roles in given path."
        ),
    )
    subparser_update.add_argument(
        "--force",
        help="Force overwriting an existing ansible role by skeleton",
        action="store_true",
    )

    arguments = vars(parser.parse_args())
    sys.exit(main(**arguments))
