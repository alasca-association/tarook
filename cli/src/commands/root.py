import click

import handlers

from lib import exec_cmd


@click.command(
    context_settings=dict(
        ignore_unknown_options=True,
        allow_extra_args=True,
    )
)
@click.option(
    "-b",
    "--branch",
    help="The branch from which to initialize the new cluster",
)
@click.pass_context
def init(ctx, branch):
    """Initialize the cluster repository"""
    handlers.init.dispatch(ctx.obj["cluster_repo"], branch, ctx.args)


@click.command
@click.pass_context
def migrate_to_release(ctx):
    """Migrate the cluster repository to the current major release"""
    exec_cmd(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/migrate-to-release.sh"
    )


@click.command
@click.pass_context
def test(ctx):
    """Run tests within the Kubernetes cluster"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/tests.sh")


@click.command
@click.pass_context
def destroy(ctx):
    """Destroy the Kubernetes cluster"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/destroy.sh")


@click.command
@click.option(
    "-s",
    "--skip-upgrade-checks",
    is_flag=True,
)
@click.argument("target_version")
@click.pass_context
def upgrade(ctx, target_version, skip_upgrade_checks):
    """Upgrade the cluster's Kubernetes version"""
    args = [target_version]
    if skip_upgrade_checks:
        args.append("-s")
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/upgrade.sh",
        args,
    )


@click.command
@click.option(
    "-s",
    "--super-admin",
    is_flag=True,
    help="Create the kubeconfig with super-admin permissions",
)
@click.pass_context
def k8s_login(ctx, super_admin):
    """Create a kubeconfig for the cluster that is valid for one week"""
    args = []
    if super_admin:
        args.append("-s")
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/k8s-login.sh",
        args,
    )
