import click

from . import exec_script


@click.group
def wireguard():
    """Wireguard management."""
    pass


@wireguard.command
@click.pass_context
def up(ctx):
    """Bring up wireguard connection"""
    exec_script(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/wg-up.sh")
