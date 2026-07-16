import click

from lib import exec_cmd


@click.group
def update():
    """Update configurations."""
    pass


@update.command
@click.option(
    "-s",
    "--skip-upgrade-checks",
    is_flag=True,
)
@click.pass_context
def frontend_nodes(ctx, skip_upgrade_checks):
    """Upgrade all Debian packages on the frontend nodes"""
    args = []
    if skip_upgrade_checks:
        args.append("-s")
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/update-frontend-nodes.sh",
        args,
    )


@update.command
@click.option(
    "-s",
    "--skip-upgrade-checks",
    is_flag=True,
)
@click.pass_context
def kubernetes_nodes(ctx, skip_upgrade_checks):
    """Upgrade all Ubuntu packages on the Kubernetes nodes"""
    args = []
    if skip_upgrade_checks:
        args.append("-s")
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/update-kubernetes-nodes.sh",
        args,
    )


@update.command
@click.pass_context
def inventory(ctx):
    """Update the inventory. This is run automatically by all dependent tasks"""
    exec_cmd(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/update-inventory.sh"
    )


#
