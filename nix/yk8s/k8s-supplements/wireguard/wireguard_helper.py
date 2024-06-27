#!/usr/bin/env python3

import pathlib
import ipaddress
import collections
import typing
import toml
import itertools
import random
import copy
import sys
import os
import json
import yaml

WG_IPAM_CONFIG_PATH = pathlib.Path(
    os.getenv("WG_IPAM_CONFIG_PATH", "config/wireguard_ipam.toml")
)
WG_PREFIX = os.getenv("WG_PREFIX", "")


class WireGuardUser(collections.namedtuple(
        "WireGuardUser",
        ["public_key", "name", "addresses_v4", "addresses_v6"])):

    @classmethod
    def fromdict(cls, d, *, with_address=True, address_optional=False):
        addressesv4_ips = {}
        addressesv6_ips = {}

        if with_address:
            addresses_v4_dict = {}
            addresses_v6_dict = {}

            if 'ips' in d and d['ips'] != {}:
                addresses_v4_dict = d['ips']
            elif 'ip' in d and d['ip'] is not None:
                addresses_v4_dict = {"0": d['ip']}

            for endpoint, ip in addresses_v4_dict.items():
                addressv4_interface = ipaddress.ip_interface(ip)
                addressesv4_ips[endpoint] = addressv4_interface.ip

                if addressv4_interface.network.prefixlen != 32:
                    raise ValueError(
                        "incorrect prefix length in IP address config: {} "
                        "(from: {!r}".format(addressv4_interface, d)
                    )

            if 'ipsv6' in d and d['ipsv6'] != {}:
                addresses_v6_dict = d['ipsv6']
            elif 'ipv6' in d and d['ipv6'] is not None:
                addresses_v6_dict = {"0": d['ipv6']}

            for endpoint, ip in addresses_v6_dict.items():
                addressv6_interface = ipaddress.ip_interface(ip)
                addressesv6_ips[endpoint] = addressv6_interface.ip

                if addressv6_interface.network.prefixlen != 128:
                    raise ValueError(
                        "incorrect prefix lenght in IP address config: {} "
                        "(from: {!r}".format(addressv6_interface, d)
                    )

            if addressesv4_ips is None and addressesv6_ips is None \
                and not address_optional: # NOQA
                raise ValueError(
                    "ip address missing on user {!r}".format(d)
                ) from None

        return cls(
            public_key=d["pub_key"],
            name=d["ident"],
            addresses_v4=addressesv4_ips,
            addresses_v6=addressesv6_ips,
        )

    def todict(self) -> typing.Mapping[str, str]:
        result = {
            "pub_key": self.public_key,
            "ident": self.name,
        }
        if self.addresses_v4 is not None:
            result["ips"] = {endpoint: str(ip)
                             for endpoint, ip in self.addresses_v4.items()}
        if self.addresses_v6 is not None:
            result["ipsv6"] = {endpoint: str(ip)
                               for endpoint, ip in self.addresses_v6.items()}
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
        *iterables: typing.Iterable[WireGuardUser],
) -> typing.Mapping[str, WireGuardUser]:
    """
    Deep merge wireguard users.

    :raise ValueError: If two users share the same public key.
    """
    result = {}
    for user in itertools.chain(*iterables):
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


def _get_endpoints_from_config(
    wg_config: typing.MutableMapping
) -> typing.List[dict]:
    """
    load endpoints from the config and return them
    """
    endpoints = copy.deepcopy(wg_config["endpoints"])

    for ep in endpoints:
        if 'ip_cidr' in ep and ep['ip_cidr'] is not None:
            ep['ip_cidr'] = ipaddress.IPv4Network(ep['ip_cidr'])
        if 'ipv6_cidr' in ep and ep['ipv6_cidr'] is not None:
            ep['ipv6_cidr'] = ipaddress.IPv6Network(ep['ipv6_cidr'])

    return endpoints


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
        reserved_addresses: typing.Set[ipaddress.IPv4Address],
        endpoint_id: int,
) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnet: The IPv4 or IPv6 subnet to allocate addresses from.
    :param reserved_addresses: A set of addresses which will never be assigned
        to a client.
    :param endpoint_id: ID of the wireguard endpoint
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
    for user in sorted(users, key=lambda x: x.addresses_v4.get(endpoint_id) is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[new_user.public_key] \
                .addresses_v4[endpoint_id]
        except KeyError:
            existing_address = new_user.addresses_v4.get(endpoint_id) \
                if new_user.addresses_v4 is not None else None

        if existing_address is not None:
            if existing_address in reserved_addresses or existing_address not in subnet:
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

            address = existing_address
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

        if new_user.addresses_v4 is not None:
            new_user.addresses_v4[endpoint_id] = address
        else:
            new_user.addresses_v4 = {endpoint_id: address}

        result[new_user.public_key] = new_user

    return result


def _assign_ipv6_addresses(
        users: typing.Iterable[WireGuardUser],
        existing_assignment: typing.Mapping[str, WireGuardUser],
        subnetv6: ipaddress.IPv6Network,
        reserved_addresses: typing.Set[ipaddress.IPv6Address],
        endpoint_id: int,
) -> typing.Mapping[str, WireGuardUser]:
    """
    Assign IP addresses to users, taking the existing assignment into account.

    :param users: An iterable of WireGuardUser objects for which to allocate
        addresses.
    :param subnetv6: The IPv4 or IPv6 subnet to allocate addresses from.
    :param reserved_addresses: A set of addresses which will never be assigned
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
    for user in sorted(users, key=lambda x: x.addresses_v6 is None):
        new_user = user

        assert new_user.public_key not in result

        try:
            existing_address = existing_assignment[new_user.public_key] \
                .addresses_v6[endpoint_id]
        except KeyError:
            existing_address = new_user.addresses_v6.get(endpoint_id) \
                if new_user.addresses_v6 is not None else None

        if existing_address is not None:
            if (existing_address in reserved_addresses or
                    existing_address not in subnetv6):
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
            address = existing_address
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

        if new_user.addresses_v6 is not None:
            new_user.addresses_v6[endpoint_id] = address
        else:
            new_user.addresses_v6 = {endpoint_id: address}

        result[new_user.public_key] = new_user

    return result


def _assign_ip_addresses_to_wg_users(
    wireguard_users: typing.Mapping[str, WireGuardUser],
    wireguard_endpoints: typing.List[dict],
) -> typing.Mapping[str, WireGuardUser]:

    # Init the (existing) IPAM config
    existing_ipam_users = _load_peers_from_ipam_config()

    assigned_v4_users = {}
    assigned_v6_users = {}

    for ep in wireguard_endpoints:
        if 'ip_cidr' in ep and ep['ip_cidr'] is not None:
            assigned_v4_users = _assign_ipv4_addresses(
                wireguard_users.values()
                if len(assigned_v4_users) == 0 else assigned_v4_users.values(),
                existing_ipam_users,
                ep['ip_cidr'],
                {ep['ip_cidr'][1], ep['ip_cidr'].broadcast_address},
                ep['id'],
            )
            if 'ipv6_cidr' not in ep or ep['ipv6_cidr'] is None:
                assigned_users = assigned_v4_users
        if 'ipv6_cidr' in ep and ep['ipv6_cidr'] is not None:
            assigned_v6_users = _assign_ipv6_addresses(
                wireguard_users.values()
                if len(assigned_v6_users) == 0 else assigned_v6_users.values(),
                existing_ipam_users,
                ep['ipv6_cidr'],
                {ep['ipv6_cidr'][1]},
                ep['id'],
            )
            if 'ip_cidr' not in ep or ep['ip_cidr'] is None:
                assigned_users = assigned_v6_users

    if len(assigned_v4_users) > 0 and len(assigned_v6_users) > 0:
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
            addresses_v6=users_b[user].addresses_v6)
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


def _dump_IPAM_config(
    assigned_users: typing.Mapping[str, WireGuardUser]
) -> None:
    WG_IPAM_CONFIG_PATH.parent.mkdir(exist_ok=True, parents=True)
    with WG_IPAM_CONFIG_PATH.open("w") as fout:
        users = [user.todict() for user in assigned_users.values()]

        for user in users:
            if 'ips' in user:
                user['ips'] = {endpoint: addr
                               for endpoint, addr in user['ips'].items()}
            if 'ipsv6' in user:
                user['ipsv6'] = {endpoint: addr
                                 for endpoint, addr in user['ipsv6'].items()}

        toml.dump({
            "wg_users": [
                user
                for user in sorted(users,
                                   key=lambda x: x['ident'])
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
    wireguard_users = _merge_wg_users([
        WireGuardUser.fromdict(item, with_address=True, address_optional=True)
        for item in wireguard_config.pop("peers", [])
    ])

    if not wireguard_users:
        raise ValueError(
            "You enabled wireguard, but did not configure any peers.")

    # Validate (all) wireguard users, require unique names
    _require_unique_names(wireguard_users.values())

    # Cast endpoint id to string, because json, yaml and toml don't like integer keys
    for ep in wireguard_config["endpoints"]:
        ep['id'] = str(ep['id'])

    # Extract the IPv4 and IPv6 subnet for wireguard from the config
    endpoints = _get_endpoints_from_config(wireguard_config)

    # Assign IP addresses to the wireguard peers
    assigned_wireguard_users = _assign_ip_addresses_to_wg_users(
        wireguard_users,
        endpoints,
    )

    # Dump the wireguard IPAM config
    _dump_IPAM_config(assigned_wireguard_users)

    wireguard_config["peers"] = sorted([
        user.todict()
        for user in assigned_wireguard_users.values()
    ], key=lambda p: p['ident'])

    return wireguard_config


def is_ipnet_disjoint(
    ipnet_string: str,
    wireguard_config: typing.MutableMapping
) -> bool:
    try:
        ipnet = ipaddress.ip_network(ipnet_string)
    except ValueError:
        raise ValueError("Invalid IP network string")

    wg_nets = _get_endpoints_from_config(wireguard_config)

    for wg_net in wg_nets:
        if wg_net['enabled']:
            # IPv4
            if isinstance(ipnet, ipaddress.IPv4Network) and 'ip_cidr' in wg_net:
                if (ipnet.subnet_of(wg_net['ip_cidr']) or
                        wg_net['ip_cidr'].subnet_of(ipnet)):
                    return False
            # IPv6
            elif isinstance(ipnet, ipaddress.IPv6Network) and 'ipv6_cidr' in wg_net:
                if (ipnet.subnet_of(wg_net['ipv6_cidr']) or
                        wg_net['ipv6_cidr'].subnet_of(ipnet)):
                    return False
            else:
                raise ValueError("{} is of unsupported IP network type".format(ipnet))
    return True


def _add_prefix(config: typing.Dict, prefix: str) -> typing.Dict:
    return {prefix + key: value for key, value in config.items()}


if __name__ == "__main__":
    src = pathlib.Path(sys.argv[1])
    dst = pathlib.Path(sys.argv[2])
    dst.parent.mkdir(exist_ok=True, parents=True)
    with (src.open("r") as sp, dst.open("w") as dp):
        config = generate_wireguard_config(json.load(sp))
        yaml.dump(_add_prefix(config, WG_PREFIX), dp)
