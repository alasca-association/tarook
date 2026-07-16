import click

from . import exec_script


@click.group
def apply():
    """Apply things"""
    pass


@apply.command
@click.pass_context
def all(ctx):
    """Apply all stages"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/apply-all.sh"
    )


@apply.command
@click.pass_context
def terraform(ctx):
    """Apply the Terraform stage"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/apply-terraform.sh"
    )


@apply.command
@click.pass_context
def gateway(ctx):
    """Apply the gateway nodes"""
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/apply-prepare-gateways.sh",
    )


@apply.command
@click.argument("playbook", required=False)
@click.pass_context
def core(ctx, playbook):
    """Apply Tarook Core"""
    args = []
    if playbook:
        args.append(playbook)
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/apply-k8s-core.sh",
        args,
    )


@apply.command
@click.argument("playbook", required=False)
@click.pass_context
def supplements(ctx, playbook):
    """Apply Tarook Supplements"""
    args = []
    if playbook:
        args.append(playbook)
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/apply-k8s-supplements.sh",
        args,
    )


@apply.command
@click.pass_context
def custom(ctx):
    """Apply custom play"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/apply-custom.sh"
    )
