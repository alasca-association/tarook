#!/usr/bin/env python3

import os
import openstack


def create_os_connection():
    username = os.environ['OS_USERNAME']
    password = os.environ['OS_PASSWORD']
    project_name = os.environ['OS_PROJECT_NAME']
    project_domain = os.environ['OS_PROJECT_DOMAIN_ID']
    user_domain = os.environ['OS_USER_DOMAIN_NAME']
    auth_url = os.environ['OS_AUTH_URL']
    region = 'f1a'

    return openstack.connect(
        auth_url=auth_url,
        project_name=project_name,
        username=username,
        password=password,
        region_name=region,
        user_domain_name=user_domain,
        project_domain_name=project_domain,
    )


def main():
    """
    This script cleans up the currently sourced OpenStack project from all
    yaook/k8s relevant resources. The order of removal is to some extend
    important as there are some dependencies between the various resources.
    """

    print("===\nConnect to OpenStack\n===")
    conn = create_os_connection()

    print("---\nDelete Floating IPs\n---")
    for floating_ip in conn.list_floating_ips():
        print(f"Delete Floating IP {floating_ip['id']}")
        conn.delete_floating_ip(floating_ip['id'])

    print("---\nDelete Server\n---")
    for server in conn.compute.servers():
        print(f"Delete server {server['id']}")
        conn.compute.delete_server(server)

    print("---\nDelete Routers\n---")
    for router in conn.network.routers():
        for router_interface in conn.list_router_interfaces(router):
            print(
                f"Delete interface {router_interface['id']}",
                f"from {router['id']}")
            conn.remove_router_interface(
                router, port_id=router_interface['id'])
        print(f"Delete router {router['id']}")
        conn.delete_router(router)

    print("---\nDelete Ports\n---")
    for port in conn.network.ports():
        print(f"Delete port {port['id']}")
        if not conn.delete_port(port['id']):
            print(f"WARNING: Deletion of port {port['id']} failed.")

    print("---\nDelete Networks\n---")
    for network in conn.list_networks():
        # do not try to delete public ipv4 network
        if network['id'] == "585ec5ec-5993-4042-93b9-264b0d82ac8e":
            continue
        # getattr(network, "subnets", default=getattr(network, "subnet_ids"))
        # throws an exception, the getattr method is overwritten by the class
        # and therefore providing default is not working as expected.
        try:
            subnets = getattr(network, "subnets")
        except AttributeError:
            subnets = getattr(network, "subnet_ids")
        for subnet in subnets:
            print(f"Delete subnet {subnet}")
            conn.network.delete_subnet(subnet)
        print(f"Delete network {network['id']}")
        conn.network.delete_network(network)

    print("---\nDelete Volumes\n---")
    for volume in conn.list_volumes():
        print(f"Delete volume {volume['id']}")
        conn.block_storage.delete_volume(volume)

    print("---\nDelete Security Groups\n---")
    for security_group in conn.list_security_groups():
        # do not delete the default security group
        if security_group['name'] == "default":
            continue
        print(f"Delete security group {security_group['id']}")
        conn.delete_security_group(security_group['id'])

    print("---\nDelete Server Groups\n---")
    for server_group in conn.list_server_groups():
        print(f"Delete server group {server_group['id']}")
        conn.delete_server_group(server_group['id'])

    print("===\nDisconnect from OpenStack\n===")
    conn.close()


if __name__ == "__main__":
    main()
