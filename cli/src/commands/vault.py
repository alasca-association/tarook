import click

from lib import exec_cmd


@click.group
def vault():
    """Vault management."""
    pass


@vault.command
@click.pass_context
def init(ctx):
    """Initialize the Vault backend"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/init.sh")


@vault.command("import")
@click.pass_context
def import_(ctx):
    """Import"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/import.sh")


@vault.command
@click.pass_context
def load_signed_intermediates(ctx):
    """Load signed intermediates"""
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "tools/vault/load-signed-intermediates.sh",
    )


@vault.command
@click.pass_context
def mkcluster_intermediate(ctx):
    """Create the relevant paths and secrets in the Vault backend
    for a new cluster using an intermediate certificate"""
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "tools/vault/mkcluster-intermediate.sh",
    )


@vault.command
@click.pass_context
def mkcluster_root(ctx):
    """Create the relevant paths and secrets in the Vault backend
    for a new cluster using a root certificate"""
    exec_cmd(
        ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/mkcluster-root.sh"
    )


@vault.command
@click.pass_context
def mkcsrs(ctx):
    """Make CSRs"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/mkcsrs.sh")


@vault.command
@click.argument("cafile")
@click.argument("cakey")
@click.argument("outfile")
@click.pass_context
def reshape_ca(ctx, cafile, cakey, outfile):
    """Reshape CA"""
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "tools/vault/reshape-ca.sh",
        [cafile, cakey, outfile],
    )


@vault.command
@click.pass_context
def rmcluster(ctx):
    """Remove a cluster from the Vault backend"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/rmcluster.sh")


@vault.command
@click.argument(
    "action", type=click.Choice(["prepare", "apply", "load-signed-intermediates"])
)
@click.pass_context
def rotate_root_ca_intermediate(ctx, action):
    """Rotate root CA intermediate"""
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "tools/vault/rotate-root-ca-intermediate.sh",
        [action],
    )


@vault.command
@click.argument("action", type=click.Choice(["prepare", "apply"]))
@click.pass_context
def rotate_root_ca_root(ctx, action):
    """Rotate root CA root"""
    exec_cmd(
        ctx.obj["cluster_repo"],
        ctx.obj["code_path"] / "tools/vault/rotate-root-ca-root.sh",
        [action],
    )


@vault.command
@click.pass_context
def update(ctx):
    """Update Vault"""
    exec_cmd(ctx.obj["cluster_repo"], ctx.obj["code_path"] / "tools/vault/update.sh")
