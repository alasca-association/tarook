import click

from lib import exec_cmd


@click.group
def wireguard():
    """Wireguard management."""
    pass


@wireguard.command
@click.option(
    "--with-kubernetes-networks",
    is_flag=True,
    help="Establish a tunnel to the Kubernetes Pod and Service network as well."
    " This can be persistently configured by setting"
    " 'TAROOK_WG_TO_K8S_NETWORKS' to 'true'.",
)
@click.pass_context
def up(ctx, with_kubernetes_networks):
    """Bring up wireguard connection"""
    args = []
    if with_kubernetes_networks:
        args.append("--with-kubernetes-networks")
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/wg-up.sh",
        args,
    )
