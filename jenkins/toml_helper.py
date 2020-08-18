#!/usr/bin/python3

import collections
import ipaddress
import itertools
import json
import pathlib
import typing

import toml


USERS_PATH = pathlib.Path("wg_user")
CONFIG_PATH = pathlib.Path("config/config.toml")
IPAM_PATH = pathlib.Path("config/wireguard_ipam.toml")
TFVARS_DIR = pathlib.Path("terraform")
TFVARS_FILE = TFVARS_DIR / "config.tfvars.json"
ANSIBLE_INVENTORY_BASEPATH = pathlib.Path("inventory")
IPAM_ANSIBLE_FILE = (
    ANSIBLE_INVENTORY_BASEPATH / "02_trampoline" / "group_vars" /
    "gateways" / "wireguard.json"
)


class WireGuardUser(collections.namedtuple(
        "WireGuardUser",
        ["public_key", "name", "address"])):

    @classmethod
    def fromdict(cls, d, *, with_address=True):
        if with_address:
            address = ipaddress.ip_interface(d["ip"])
            if address.network.prefixlen != 32:
                raise ValueError(
                    "incorrect prefix length in IP address config: {} "
                    "(from: {!r}".format(address, d)
                )
        else:
            address = None

        return cls(
            public_key=d["pub_key"],
            name=d["ident"],
            address=address,
        )

    def todict(self) -> typing.Mapping[str, str]:
        result = {
            "pub_key": self.public_key,
            "ident": self.name,
        }
        if self.address is not None:
            result["ip"] = str(self.address)
        return result


def load_wg_users(
        source_dir: pathlib.Path
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Read all wireguard users from all ``*.toml`` files in `source_dir`.

    Return the wireguard users as mapping which maps the public key to the
    user object.
    """
    wg_users = {}
    for filepath in source_dir.iterdir():
        if not filepath.name.endswith(".toml"):
            continue
        with filepath.open("r") as f:
            # we don’t want to carry any address information from the global
            # repository into the clusters.
            user = WireGuardUser.fromdict(toml.load(f), with_address=False)
        if user.public_key in wg_users:
            raise ValueError(
                "duplicate public key in wg_user repository: {} in use by "
                "{!r} and {!r}".format(
                    user.public_key,
                    user.name,
                    wg_users[user.public_key].name,
                )
            )
        wg_users[user.public_key] = user

    return wg_users


def index_wg_users(
        users: typing.Iterable[WireGuardUser]
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Index an iterable of wireguard users by their public key.

    If a public key exists more than once, it is undefined which user is
    included in the result.
    """
    result = {}
    for user in users:
        result[user.public_key] = user
    return result


def merge_wg_users(
        users_a: typing.Iterable[WireGuardUser],
        users_b: typing.Iterable[WireGuardUser],
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Deep merge wireguard users.

    :raise ValueError: If two users share the same public key.
    """
    result = {}
    for user in itertools.chain(users_a, users_b):
        key = user.public_key
        if key in result:
            raise ValueError(
                "users {!r} and {!r} have the same public key",
                user.name,
                result[key].name,
            )
        result[key] = user
    return result


def require_unique_names(users: typing.Iterable[WireGuardUser]):
    seen_names = {}
    for user in users:
        if user.name in seen_names:
            raise ValueError(
                "duplicate wireguard user name ({!r}) in {!r} and {!r}".format(
                    user.name, user, seen_names[user.name],
                )
            )
        seen_names[user.name] = user


def assign_ip_addresses(
        users: typing.Iterable[WireGuardUser],
        existing_assignment: typing.Mapping[str, WireGuardUser],
        subnet: ipaddress.IPv4Network,
        reserved_addresses: typing.Set[ipaddress.IPv4Address],
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnet: The IPv4 subnet to allocate addresses from.
    :param reserved_addresses: A set of addresess which will never be assigned
        to a client.
    :raises RuntimeError: If the subnet is too large.
    :raises ValueError: If an address conflict arises.
    :raises ValueError: If there are not enough addresses in the subnet to
        serve all users.

    Users which already have an address assigned are preferred. Other users
    will get addresses from the given subnet as necessary.
    """

    if subnet.num_addresses > 65536:
        raise RuntimeError(
            "this is a safety net: the subnet you chose has more than 2**16 "
            "addresses. we don't know if this code will eat your machine if "
            "you try to use it, so remove this safeguard at your own risk."
        )

    free_addresses = set(subnet) - reserved_addresses
    free_addresses.discard(subnet.network_address)
    free_addresses.discard(subnet.broadcast_address)
    result = {}
    for user in sorted(users, key=lambda x: x.address is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[new_user.public_key].address
        except KeyError:
            existing_address = new_user.address

        if existing_address is not None:
            try:
                free_addresses.remove(existing_address.ip)
            except KeyError:
                raise ValueError(
                    "user {!r} has the address {!s} assigned which is not "
                    "in the subnet {!s} or already in use by a different "
                    "user".format(
                        new_user.name,
                        existing_address,
                        subnet,
                    )
                )

            new_user = new_user._replace(address=existing_address)
        else:
            try:
                address = free_addresses.pop()
            except KeyError:
                raise ValueError(
                    "failed to allocate address for {!r}: no more addresses "
                    "left".format(new_user.name)
                )

            # not allocated yet, use next free address
            new_user = new_user._replace(
                address=ipaddress.ip_interface(address)
            )

        result[new_user.public_key] = new_user

    return result


def main():
    with CONFIG_PATH.open("r") as fin:
        config = toml.load(fin)
    try:
        with IPAM_PATH.open("r") as fin:
            ipam = toml.load(fin)
    except FileNotFoundError:
        ipam = {}

    try:
        subnet = ipaddress.IPv4Network(config["ansible"]["02_trampoline"]["group_vars"]["gateways"]["wg_ip_cidr"])  # NOQA
    except (ValueError, TypeError, KeyError):
        raise ValueError(
            "ansible.02_trampoline.group_vars.gateways.wg_ip_cidr is not set "
            "or not an IPv4 network",
        )

    TFVARS_DIR.mkdir(exist_ok=True)

    terraform_cfg = config["terraform"]
    with open(TFVARS_FILE, "w") as fout:
        json.dump(terraform_cfg, fout)

    ansible_cfg = config["ansible"]

    company_users = load_wg_users(USERS_PATH)

    # note that we explicitly remove the wg_peers config here since we write
    # the wg_peers in a separate file later on.
    cluster_wg_config = \
        ansible_cfg["02_trampoline"]["group_vars"]["gateways"].pop(
            "wg_peers", []
        )
    cluster_users = [
        WireGuardUser.fromdict(item, with_address=True)
        for item in cluster_wg_config
    ]

    # merge wg users while rejecting duplicates, since a company and a
    # cluster-specific user should never share private keys
    configured_users = merge_wg_users(company_users.values(), cluster_users)

    require_unique_names(configured_users.values())

    ipam_users = index_wg_users([
        WireGuardUser.fromdict(item, with_address=True)
        for item in ipam.get("users", [])
    ])

    assigned_users = assign_ip_addresses(
        configured_users.values(),
        ipam_users,
        subnet,
        {subnet[1]},
    )

    with IPAM_PATH.open("w") as fout:
        toml.dump({
            "users": [
                user.todict()
                for user in sorted(assigned_users.values(),
                                   key=lambda x: x.address)
            ]
        }, fout)

    for stage, stage_cfg in ansible_cfg.items():
        for var_type, vars_cfg in stage_cfg.items():
            for entity, entity_cfg in vars_cfg.items():
                cfg_path = (
                    ANSIBLE_INVENTORY_BASEPATH / stage / var_type /
                    entity / "config.json"
                )
                cfg_path.parent.mkdir(exist_ok=True, mode=0o750,
                                      parents=True)
                with cfg_path.open("w") as f:
                    json.dump(entity_cfg, f)

    with IPAM_ANSIBLE_FILE.open("w") as fout:
        json.dump({
            "wg_peers": [
                user.todict()
                for user in assigned_users.values()
            ]
        }, fout)


if __name__ == "__main__":
    import sys
    sys.exit(main() or 0)
