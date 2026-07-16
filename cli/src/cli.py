from pathlib import Path

import click

from commands.apply import apply
from commands.root import init, k8s_login, migrate_to_release, test, upgrade
from commands.update import update
from commands.vault import vault
from commands.wireguard import wireguard


@click.group()
@click.option(
    "--cluster-repo",
    default=".",
    envvar="TAROOK_CLUSTER_REPO",
    type=click.Path(file_okay=False, dir_okay=True),
    help="The cluster repository on which to operate",
)
@click.option(
    "--code-path",
    envvar="TAROOK_CODE_PATH",
    type=click.Path(file_okay=False, dir_okay=True),
    help="The path to the repository containing the Tarook codebase",
)
@click.pass_context
def cli(ctx, cluster_repo, code_path):
    """Tarook cluster management CLI."""
    ctx.ensure_object(dict)
    ctx.obj["cluster_repo"] = Path(cluster_repo)

    if code_path:
        ctx.obj["code_path"] = Path(code_path)
    else:
        ctx.obj["code_path"] = Path(cluster_repo) / "managed-k8s"


for cmd in [
    init,
    migrate_to_release,
    test,
    upgrade,
    k8s_login,
    apply,
    update,
    vault,
    wireguard,
]:
    cli.add_command(cmd)

if __name__ == "__main__":
    cli()
