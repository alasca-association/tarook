import click

from . import exec_script


@click.group
def update():
    """Update configurations."""
    pass


@update.command
@click.pass_context
def frontend_nodes(ctx):
    """Upgrade all Debian packages on the frontend nodes"""
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/update-frontend-nodes.sh",
    )


@update.command
@click.pass_context
def kubernetes_nodes(ctx):
    """Upgrade all Ubuntu packages on the Kubernetes nodes"""
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/update-kubernetes-nodes.sh",
    )


@update.command
@click.pass_context
def inventory(ctx):
    """Update the inventory. This is run automatically by all dependent tasks"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/update-inventory.sh"
    )


#
