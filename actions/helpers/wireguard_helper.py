#!/usr/bin/python3

import pathlib
import ipaddress
import collections
import typing
import toml
import itertools
import random
import os

WG_COMPANY_USERS_PATH = pathlib.Path("wg_user")
WG_IPAM_CONFIG_PATH = pathlib.Path("config/wireguard_ipam.toml")


class WireGuardUser(collections.namedtuple(
        "WireGuardUser",
        ["public_key", "name", "address_v4", "address_v6"])):

    @classmethod
    def fromdict(cls, d, *, with_address=True, address_optional=False):
        if with_address:
            try:
                addressv4_interface = ipaddress.ip_interface(d["ip"])
                addressv4_ip = addressv4_interface.ip
            except KeyError:
                addressv4_ip = None
            else:
                if addressv4_interface.network.prefixlen != 32:
                    raise ValueError(
                        "incorrect prefix length in IP address config: {} "
                        "(from: {!r}".format(addressv4_interface, d)
                    )

            try:
                addressv6_interface = ipaddress.ip_interface(d["ipv6"])
                addressv6_ip = addressv6_interface.ip
            except KeyError:
                addressv6_ip = None
            else:
                if addressv6_interface.network.prefixlen != 128:
                    raise ValueError(
                        "incorrect prefix lenght in IP address config: {} "
                        "(from: {!r}".format(addressv6_interface, d)
                    )

            if addressv4_ip is None and addressv6_ip is None and not address_optional: # NOQA
                raise ValueError(
                    "ip address missing on user {!r}".format(d)
                ) from None
        else:
            addressv4_ip = None
            addressv6_ip = None

        return cls(
            public_key=d["pub_key"],
            name=d["ident"],
            address_v4=addressv4_ip,
            address_v6=addressv6_ip,
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


def _index_wg_users(
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


def _merge_wg_users(
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


def _require_unique_names(
    users: typing.Iterable[WireGuardUser]
) -> bool:
    seen_names = {}
    for user in users:
        if user.name in seen_names:
            raise ValueError(
                "duplicate wireguard user name ({!r}) in {!r} and {!r}".format(
                    user.name, user, seen_names[user.name],
                )
            )
        seen_names[user.name] = user
    return True


def _get_subnets_from_config(
    wg_config: typing.MutableMapping
) -> typing.Tuple[ipaddress.IPv4Network, ipaddress.IPv6Network]:
    """
    load IPv4 and IPv6 subnet from the config and return them
    """
    subnetv4 = None
    subnetv6 = None
    if "ip_cidr" in wg_config:
        subnetv4 = ipaddress.IPv4Network(wg_config["ip_cidr"])
    if "ipv6_cidr" in wg_config:
        subnetv6 = ipaddress.IPv6Network(wg_config["ipv6_cidr"])
    # legacy
    if "wg_ip_cidr" in wg_config:
        subnetv4 = ipaddress.IPv4Network(wg_config["wg_ip_cidr"])
    if "wg_ipv6_cidr" in wg_config:
        subnetv6 = ipaddress.IPv6Network(wg_config["wg_ipv6_cidr"])
    if not subnetv4 and not subnetv6:
        raise ValueError(
            "Wireguard section has neither wg_ip_cidr nor wg_ipv6_cidr set ",
        )

    return subnetv4, subnetv6


def _generate_ipaddress(
    subnet: typing.Union[ipaddress.IPv4Network, ipaddress.IPv6Network]
) -> typing.Union[ipaddress.IPv4Address, ipaddress.IPv6Address]:
    random.seed()
    return subnet.network_address + random.getrandbits(
        subnet.max_prefixlen - subnet.prefixlen
    )


def _assign_ipv4_addresses(
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
                address = _generate_ipaddress(subnet)
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


def _assign_ipv6_addresses(
        users: typing.Iterable[WireGuardUser],
        existing_assignment: typing.Mapping[str, WireGuardUser],
        subnetv6: ipaddress.IPv6Network,
        reserved_addresses: typing.Set[ipaddress.IPv6Address]
) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnetv6: The IPv4 or IPv6 subnet to allocate addresses from.
    :param reserved_addresses: A set of addresess which will never be assigned
        to a client.
    :raises RuntimeError: If the subnet is too large.
    :raises ValueError: If an address conflict arises.
    :raises ValueError: If there are not enough addresses in the subnet to
        serve all users.

    Users which already have an address assigned are preferred. Other users
    will get addresses from the given subnet as necessary.
    """

    if subnetv6.num_addresses > 2**64:
        raise RuntimeError(
            "this is a safety net: the subnet you chose has more than 2**64 "
            "addresses. we don't know if this code will eat your "
            "machine if you try to use it, so remove this safeguard at your "
            "own risk."
        )

    result = {}
    for user in sorted(users, key=lambda x: x.address_v6 is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[
                new_user.public_key].address_v6
        except KeyError:
            existing_address = new_user.address_v6

        if existing_address is not None:
            if existing_address in reserved_addresses:
                raise ValueError(
                    "user {!r} has the address {!s} assigned which is not "
                    "in the subnet {!s} or already in use by a different "
                    "user".format(
                        new_user.name,
                        existing_address,
                        subnetv6,
                    )
                )
            reserved_addresses.add(existing_address)
            new_user = new_user._replace(address_v6=existing_address)
        else:
            # a new address is randomly generated, in a case of a collision
            # it is checked if the set of reserved_addresses is full
            # if not the random IP address generation is repeated
            while True:
                address = _generate_ipaddress(subnetv6)
                if address in reserved_addresses:
                    if len(reserved_addresses) == subnetv6.num_addresses:
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


def _assign_ip_addresses_to_wg_users(
    subnetv4: ipaddress.IPv4Network,
    subnetv6: ipaddress.IPv6Network,
    wireguard_users: typing.Mapping[str, WireGuardUser],
) -> typing.Mapping[str, WireGuardUser]:

    # Init the (existing) IPAM config
    existing_ipam_users = _load_peers_from_ipam_config()

    if subnetv4:
        assigned_v4_users = _assign_ipv4_addresses(
            wireguard_users.values(),
            existing_ipam_users,
            subnetv4,
            {subnetv4[1], subnetv4.broadcast_address},
        )
        if not subnetv6:
            assigned_users = assigned_v4_users
    if subnetv6:
        assigned_v6_users = _assign_ipv6_addresses(
            wireguard_users.values(),
            existing_ipam_users,
            subnetv6,
            {subnetv6[1]},
        )
        if not subnetv4:
            assigned_users = assigned_v6_users
    if subnetv4 and subnetv6:
        assigned_users = _merge_user_ipaddress(
            assigned_v4_users,
            assigned_v6_users
        )

    return assigned_users


def _merge_user_ipaddress(users_a: typing.Iterable[WireGuardUser],
                          users_b: typing.Iterable[WireGuardUser],
                          ) -> typing.Iterable[WireGuardUser]:
    for user in users_a:
        users_a[user] = users_a[user]._replace(
            address_v6=users_b[user].address_v6)
    return users_a


def _load_peers_from_ipam_config(
    path_to_ipam_conf: pathlib.Path = WG_IPAM_CONFIG_PATH
):
    """
    Load configured wg peers from IPAM_PATH
    """
    try:
        with WG_IPAM_CONFIG_PATH.open("r") as fin:
            ipam_config = toml.load(fin)
    except FileNotFoundError:
        ipam_config = {}
    return _index_wg_users([
        WireGuardUser.fromdict(item, with_address=True)
        for item in ipam_config.get("wg_users", [])
    ])


def _load_wireguard_company_users(
        source_dir: pathlib.Path = WG_COMPANY_USERS_PATH
) -> typing.Mapping[str, WireGuardUser]:
    """
    Read all wireguard users from all ``*.toml`` files in `source_dir`.
    Default path should be the path to the "wg-users" repository

    Return the wireguard users as mapping which maps the public key to the
    user object.
    """
    wg_company_users = {}

    for filepath in source_dir.iterdir():
        if not filepath.name.endswith(".toml"):
            continue
        with filepath.open("r") as f:
            # we don’t want to carry any address information from the global
            # repository into the clusters.
            user = WireGuardUser.fromdict(toml.load(f), with_address=False)
        if user.public_key in wg_company_users:
            raise ValueError(
                "duplicate public key in wg_user repository: {} in use by "
                "{!r} and {!r}".format(
                    user.public_key,
                    user.name,
                    wg_company_users[user.public_key].name,
                )
            )
        wg_company_users[user.public_key] = user

    return wg_company_users


def _dump_IPAM_config(
    assigned_users: typing.Mapping[str, WireGuardUser]
) -> None:
    with WG_IPAM_CONFIG_PATH.open("w") as fout:
        toml.dump({
            "wg_users": [
                user.todict()
                for user in sorted(assigned_users.values(),
                                   key=lambda x: x.name)
            ]
        }, fout)


def generate_wireguard_config(
    wireguard_config: typing.MutableMapping,
) -> None:
    """
    Holistic function to generate wireguard configration including
    all wireguard peers
    """

    # Init the configured users as wireguard peers
    wireguard_configured_users = [
        WireGuardUser.fromdict(item, with_address=True, address_optional=True)
        for item in wireguard_config.pop("peers", [])
    ]

    # Check if C&H company members should be added as wireguard peers
    wireguard_rollout_company_users = \
        (os.getenv('WG_COMPANY_USERS', 'false') == 'true') \
        or \
        wireguard_config.get("rollout_company_users", False)

    # Init the company members as wireguard peers
    wireguard_company_users = []
    if wireguard_rollout_company_users:
        wireguard_company_users = _load_wireguard_company_users()

    # Merge the wireguard users (configured and company) while rejecting
    # duplicates, since a company and a cluster-specific (additional) user
    # should never share private keys
    wireguard_users = _merge_wg_users(
        wireguard_company_users.values(),
        wireguard_configured_users
    )

    # Validate (all) wireguard users, require unique names
    _require_unique_names(wireguard_users.values())

    # Extract the IPv4 and IPv6 subnet for wireguard from the config
    subnetv4, subnetv6 = _get_subnets_from_config(wireguard_config)

    # Assign IP addresses to the wireguard peers
    assigned_wireguard_users = _assign_ip_addresses_to_wg_users(
        subnetv4,
        subnetv6,
        wireguard_users,
    )

    # Dump the wireguard IPAM config
    _dump_IPAM_config(assigned_wireguard_users)

    wireguard_config["peers"] = [
        user.todict()
        for user in assigned_wireguard_users.values()
    ]

    return wireguard_config
