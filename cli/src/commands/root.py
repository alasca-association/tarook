import click

from . import exec_script


@click.command
@click.pass_context
def init(ctx):
    """Initialize the cluster repository"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/init-cluster-repo.sh"
    )


@click.command
@click.pass_context
def migrate_to_release(ctx):
    """Migrate the cluster repository to the current major release"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/migrate-to-release.sh"
    )


@click.command
@click.pass_context
def test(ctx):
    """Run tests within the Kubernetes cluster"""
    exec_script(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/tests.sh")


@click.command
@click.pass_context
def destroy(ctx):
    """Destroy the Kubernetes cluster"""
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/destroy.sh"
    )


@click.command
@click.argument("target_version")
@click.pass_context
def upgrade(ctx, target_version):
    """Upgrade the cluster's Kubernetes version"""
    exec_script(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "actions/upgrade.sh",
        [target_version],
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
    exec_script(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "actions/k8s-login.sh", args
    )
