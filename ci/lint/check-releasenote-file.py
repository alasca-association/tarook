#!/usr/bin/env python3

import sys
import os
import tomllib
import git


def load_types_from_file(config_file: str) -> list:
    with open(config_file, "rb") as conffile:
        config = tomllib.load(conffile)

    types = []
    for type in config['tool']['towncrier']['type']:
        types.append(type['directory'])

    return types


def get_releasenote_files(
        repository, target_branch: str, note_directory: str) -> list:
    for remote in repository.remotes:
        remote.fetch()

    note_files = repository.git.diff(
        target_branch,
        "--name-only", "--diff-filter=A",
        "--", note_directory
    )

    print(note_files)

    if not note_files:
        raise RuntimeError("No releasenote file added. \
            Make sure to provide a file with your MR.")

    files_list = (str(note_files).split("\n"))

    return files_list


def split_filename(file: str) -> [str, str]:
    fname = os.path.basename(file)
    splitted = fname.split('.')
    number = splitted[0]
    type = splitted[1]

    return number, type


if __name__ == "__main__":
    repo_adr = sys.argv[1]
    target_branch = sys.argv[2]
    towncrier_config = sys.argv[3]
    MR_IID = sys.argv[4]
    note_directory = sys.argv[5]
    fork = sys.argv[6]
    hotfix = sys.argv[7]

    repository = git.Repo(repo_adr)

    types = load_types_from_file(towncrier_config)
    note_files = get_releasenote_files(repository, target_branch, note_directory)

    for file in note_files:
        number, note = split_filename(file)
        if note not in types:
            raise RuntimeError("Releasenote type not supported. Supported types are: ",
                               types)

        if (number != MR_IID):
            if (fork == "True"):
                raise RuntimeError("Provided MR-ID in releasenotes doesn't \
                                    match the actual MR-ID. \
                                    Please update the name of the releasenote file.")
            if (hotfix == "True" and number.isdigit()):
                print("Provided MR-ID in releasenotes doesn't \
                        match the actual MR-ID, but we asume you know \
                        what you are doing.")
                sys.exit(13)
            fname = os.path.basename(file).split('.')
            dirname = os.path.dirname(file)
            fname[0] = MR_IID
            new_base = '.'.join(fname)
            newpath = os.path.join(dirname, new_base)
            os.rename(file, newpath)
            print(fname, newpath)
