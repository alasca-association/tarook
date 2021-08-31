#!/usr/bin/python3

import pathlib
import collections
import typing
import toml

# Path to the config file which contains all currently configured users
PASS_USERS_FILE = pathlib.Path("config/pass_users.toml")
# Path to the company users file
PASSWORDSTORE_COMPANY_USERS_FILE = pathlib.Path(
    "passwordstore-users") / "main.toml"


class PasswordstoreUser(collections.namedtuple(
        "PasswordstoreUser", ["ident", "gpg_id"])):

    @classmethod
    def fromdict(cls, d):
        return cls(ident=d["ident"], gpg_id=d["gpg_id"])

    def todict(self) -> typing.Mapping[str, str]:
        return {"ident": self.ident,
                "gpg_id": self.gpg_id}


def _load_password_store_users(
    source_dir: pathlib.Path = PASS_USERS_FILE
):
    """
    Load currently configured pass users
    """
    try:
        with PASS_USERS_FILE.open("r") as fin:
            pass_users_config = toml.load(fin)
    except FileNotFoundError:
        pass_users_config = {}

    return [
        PasswordstoreUser.fromdict(user)
        for user in pass_users_config.get("passwordstore_users", [])
    ]


def _dump_pass_users_config(
    pass_users: typing.List[PasswordstoreUser]
) -> None:
    with PASS_USERS_FILE.open("w") as fout:
        toml.dump({
            "passwordstore_users": [
                user.todict()
                for user in sorted(pass_users,
                                   key=lambda x: x.ident)
            ]
        }, fout)


def _load_passwordstore_company_users(
    company_users_config_path: pathlib.Path
    = PASSWORDSTORE_COMPANY_USERS_FILE
) -> typing.List[PasswordstoreUser]:
    with company_users_config_path.open("r") as f:
        return [PasswordstoreUser.fromdict(u)
                for u in toml.load(f)["users"]]


def generate_passwordstore_config(
    pass_config: typing.MutableMapping
) -> None:
    """
    Function to initialize all passwordstore users
    (company and additionally configured) and dump
    them to the config directory
    """

    # Init all additionally configured users
    additional_users_config = pass_config.get(
        "additional_users", [])
    passwordstore_users = [
        PasswordstoreUser.fromdict(u)
        for u in additional_users_config
    ]

    # Add company users if configured so
    if pass_config.get("rollout_company_users", True):
        passwordstore_users.extend(_load_passwordstore_company_users())  # NOQA

    # ToDo: dump to PASS USERS FILE
    _dump_pass_users_config(passwordstore_users)

    return {"users": [
            u.todict() for u in passwordstore_users]}
