#!/usr/bin/python3

import collections
import ipaddress
import itertools
import json
import pathlib
import typing
import random

import toml
import yaml

USERS_PATH = pathlib.Path("wg_user")
PASSWORDSTORE_USERS_FILE = pathlib.Path("passwordstore-users") / "main.toml"
CONFIG_PATH = pathlib.Path("config/config.toml")
IPAM_PATH = pathlib.Path("config/wireguard_ipam.toml")
TFVARS_DIR = pathlib.Path("terraform")
TFVARS_FILE = TFVARS_DIR / "config.tfvars.json"
ANSIBLE_INVENTORY_BASEPATH = pathlib.Path("inventory")
IPAM_ANSIBLE_FILE = (
    ANSIBLE_INVENTORY_BASEPATH / "02_trampoline" / "group_vars" /
    "gateways" / "wireguard.json"
)


class PasswordstoreUser(collections.namedtuple(
        "PasswordstoreUser", ["ident", "gpg_id"])):

    @classmethod
    def fromdict(cls, d):
        return cls(ident=d["ident"], gpg_id=d["gpg_id"])

    def todict(self) -> typing.Mapping[str, str]:
        return {"ident": self.ident,
                "gpg_id": self.gpg_id}


def load_passwordstore_users(
        config_path: pathlib.Path
        ) -> typing.List[PasswordstoreUser]:
    with config_path.open("r") as f:
        return [PasswordstoreUser.fromdict(u) for u in toml.load(f)["users"]]


class WireGuardUser(collections.namedtuple(
        "WireGuardUser",
        ["public_key", "name", "address_v4", "address_v6"])):

    @classmethod
    def fromdict(cls, d, *, with_address=True, address_optional=False):
        if with_address:
            try:
                address = ipaddress.ip_interface(d["ip"])
            except KeyError:
                address = None
            else:
                if address.network.prefixlen != 32:
                    raise ValueError(
                        "incorrect prefix length in IP address config: {} "
                        "(from: {!r}".format(address, d)
                    )

            try:
                addressv6 = ipaddress.ip_interface(d["ipv6"])
            except KeyError:
                addressv6 = None
            else:
                if addressv6.network.prefixlen != 128:
                    raise ValueError(
                        "incorrect prefix lenght in IP address config: {} "
                        "(from: {!r}".format(address, d)
                    )

            if address is None and addressv6 is None and not address_optional:
                raise ValueError(
                    "ip address missing on user {!r}".format(d)
                ) from None
        else:
            address = None
            addressv6 = None

        return cls(
            public_key=d["pub_key"],
            name=d["ident"],
            address_v4=address,
            address_v6=addressv6,
        )

    def todict(self) -> typing.Mapping[str, str]:
        result = {
            "pub_key": self.public_key,
            "ident": self.name,
        }
        if self.address_v4 is not None:
            result["ip"] = str(self.address_v4)
        if self.address_v6 is not None:
            result["ipv6"] = str(self.address_v6)
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


def generate_ipaddress(
        subnet: typing.Union[ipaddress.IPv4Network, ipaddress.IPv6Network]
        ):
    random.seed()
    return subnet.network_address + random.getrandbits(
            subnet.max_prefixlen - subnet.prefixlen
            )


def assign_ipv4_addresses(
        users: typing.Iterable[WireGuardUser],
        existing_assignment: typing.Mapping[str, WireGuardUser],
        subnet: ipaddress.IPv4Network,
        reserved_addresses: typing.Set[ipaddress.IPv4Address]
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnet: The IPv4 or IPv6 subnet to allocate addresses from.
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
            "addresses. we don't know if this code will eat your "
            "machine if you try to use it, so remove this safeguard at your "
            "own risk."
        )

    result = {}
    for user in sorted(users, key=lambda x: x.address_v4 is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[
                                new_user.public_key].address_v4
        except KeyError:
            existing_address = new_user.address_v4

        if existing_address is not None:
            if existing_address in reserved_addresses:
                raise ValueError(
                    "user {!r} has the address {!s} assigned which is not "
                    "in the subnet {!s} or already in use by a different "
                    "user".format(
                        new_user.name,
                        existing_address,
                        subnet,
                    )
                )
            reserved_addresses.add(existing_address)
            new_user = new_user._replace(address_v4=existing_address)
        else:
            # a new address is randomly generated, in a case of a collision
            # it is checked if the set of reserved_addresses is full
            # if not the random IP address generation is repeated
            while True:
                address = generate_ipaddress(subnet)
                if address in reserved_addresses:
                    if len(reserved_addresses) == subnet.num_addresses:
                        raise ValueError(
                            "failed to allocate address for {!r}: "
                            "no more addresses left".format(new_user.name)
                        )
                else:
                    reserved_addresses.add(address)
                    break

            new_user = new_user._replace(
                address_v4=address
            )

        result[new_user.public_key] = new_user

    return result


def assign_ipv6_addresses(
        users: typing.Iterable[WireGuardUser],
        existing_assignment: typing.Mapping[str, WireGuardUser],
        subnet: ipaddress.IPv6Network,
        reserved_addresses: typing.Set[ipaddress.IPv6Address]
        ) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnet: The IPv4 or IPv6 subnet to allocate addresses from.
    :param reserved_addresses: A set of addresess which will never be assigned
        to a client.
    :raises RuntimeError: If the subnet is too large.
    :raises ValueError: If an address conflict arises.
    :raises ValueError: If there are not enough addresses in the subnet to
        serve all users.

    Users which already have an address assigned are preferred. Other users
    will get addresses from the given subnet as necessary.
    """

    if subnet.num_addresses > 2**64:
        raise RuntimeError(
            "this is a safety net: the subnet you chose has more than 2**64 "
            "addresses. we don't know if this code will eat your "
            "machine if you try to use it, so remove this safeguard at your "
            "own risk."
        )

    result = {}
    for user in sorted(users, key=lambda x: x.address_v4 is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[
                                new_user.public_key].address_v6
        except KeyError:
            existing_address = new_user.address_v4

        if existing_address is not None:
            if existing_address in reserved_addresses:
                raise ValueError(
                    "user {!r} has the address {!s} assigned which is not "
                    "in the subnet {!s} or already in use by a different "
                    "user".format(
                        new_user.name,
                        existing_address,
                        subnet,
                    )
                )
            reserved_addresses.add(existing_address)
            new_user = new_user._replace(address_v6=existing_address)
        else:
            # a new address is randomly generated, in a case of a collision
            # it is checked if the set of reserved_addresses is full
            # if not the random IP address generation is repeated
            while True:
                address = generate_ipaddress(subnet)
                if address in reserved_addresses:
                    if len(reserved_addresses) == subnet.num_addresses:
                        raise ValueError(
                            "failed to allocate address for {!r}: "
                            "no more addresses left".format(new_user.name)
                        )
                else:
                    reserved_addresses.add(address)
                    break

            new_user = new_user._replace(
                address_v6=address
            )

        result[new_user.public_key] = new_user

    return result


def merge_user_ipaddress(users_a: typing.Iterable[WireGuardUser],
                         users_b: typing.Iterable[WireGuardUser],
                         ) -> typing.Iterable[WireGuardUser]:
    for user in users_a:
        users_a[user] = users_a[user]._replace(
                address_v6=users_b[user].address_v6)
    return users_a


def main():
    with CONFIG_PATH.open("r") as fin:
        config = toml.load(fin)
    try:
        with IPAM_PATH.open("r") as fin:
            ipam = toml.load(fin)
    except FileNotFoundError:
        ipam = {}

    subnet = None
    subnetv6 = None
    if "wg_ip_cidr" in \
            config["ansible"]["02_trampoline"]["group_vars"]["gateways"]:
        subnet = ipaddress.IPv4Network(config["ansible"]["02_trampoline"]["group_vars"]["gateways"]["wg_ip_cidr"])  # NOQA
    if "wg_ipv6_cidr" in \
            config["ansible"]["02_trampoline"]["group_vars"]["gateways"]:
        subnetv6 = ipaddress.IPv6Network(config["ansible"]["02_trampoline"]["group_vars"]["gateways"]["wg_ipv6_cidr"])  # NOQA
    if not subnet and not subnetv6:
        raise ValueError(
            "ansible.02_trampoline.group_vars.gateways.wg_ip_cidr is not set ",
        )

    TFVARS_DIR.mkdir(exist_ok=True)

    terraform_cfg = config["terraform"]
    with open(TFVARS_FILE, "w") as fout:
        json.dump(terraform_cfg, fout)

    ansible_cfg = config["ansible"]

    ansible_common_cfg = config["ansible_common"]

    company_users = load_wg_users(USERS_PATH)
    if ansible_common_cfg.pop("passwordstore_rollout_company_users", True):
        passwordstore_company_users = load_passwordstore_users(PASSWORDSTORE_USERS_FILE) # NOQA
    else:
        passwordstore_company_users = []

    # note that we explicitly remove the wg_peers config here since we write
    # the wg_peers in a separate file later on.
    cluster_wg_config = \
        ansible_cfg["02_trampoline"]["group_vars"]["gateways"].pop(
            "wg_peers", []
        )
    cluster_users = [
        WireGuardUser.fromdict(item, with_address=True, address_optional=True)
        for item in cluster_wg_config
    ]

    passwordstore_cluster_users = [PasswordstoreUser.fromdict(u)
            for u in ansible_common_cfg.pop("passwordstore_additional_users", [])] # NOQA

    # merge wg users while rejecting duplicates, since a company and a
    # cluster-specific user should never share private keys
    configured_users = merge_wg_users(company_users.values(), cluster_users)

    passwordstore_users = passwordstore_company_users + \
        passwordstore_cluster_users

    require_unique_names(configured_users.values())

    ipam_users = index_wg_users([
        WireGuardUser.fromdict(item, with_address=True)
        for item in ipam.get("users", [])
    ])

    if subnet:
        assigned_v4_users = assign_ipv4_addresses(
            configured_users.values(),
            ipam_users,
            subnet,
            {subnet[1], subnet.broadcast_address},
        )
        if not subnetv6:
            assigned_users = assigned_v4_users
    if subnetv6:
        assigned_v6_users = assign_ipv6_addresses(
            configured_users.values(),
            ipam_users,
            subnetv6,
            {subnetv6[1]},
        )
        if not subnet:
            assigned_users = assigned_v6_users
    if subnet and subnetv6:
        assigned_users = merge_user_ipaddress(
                        assigned_v4_users,
                        assigned_v6_users
                        )

    with IPAM_PATH.open("w") as fout:
        toml.dump({
            "users": [
                user.todict()
                for user in sorted(assigned_users.values(),
                                   key=lambda x: x.name)
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

    # Write the contents of `ansible_common`, i.e., passwordstore_users
    # to `group_vars/all/all.yaml`. Needs additional work to support other
    # kinds of entries.
    for stage in ansible_cfg.keys():
        cfg_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage / "group_vars" /
            "all" / "all.yaml"
        )
        cfg_path.parent.mkdir(exist_ok=True, mode=0o750, parents=True)
        with cfg_path.open("w") as f:
            yaml.dump({"passwordstore_users": [
                u.todict() for u in passwordstore_users]}, f)

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
