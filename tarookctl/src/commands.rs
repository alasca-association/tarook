/// Commands and subcommands for tarookctl
use clap::{Args, Subcommand};

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize something
    #[command(subcommand)]
    Init(InitCommands),
    /// Apply things
    #[command(subcommand)]
    Apply(ApplyCommands),
    #[command(subcommand)]
    Update(UpdateCommands),
    Upgrade {},
    #[command(subcommand)]
    Migrate(MigrateCommands),
    #[command(subcommand)]
    Vault(VaultCommands),
    /// k8s
    #[command(subcommand)]
    Kubernetes(KubernetesCommands),
    #[command(subcommand)]
    Tests(TestsCommands),
    #[command(subcommand)]
    Connection(ConnectionCommands),
    Ssh {},
}

#[derive(Subcommand, Debug)]
pub enum InitCommands {
    Git,
}

#[derive(Subcommand, Debug)]
pub enum ApplyCommands {
    All,
    Terraform,
    Gateway,
    Custom,
    Supplements,
}

#[derive(Subcommand, Debug)]
pub enum UpdateCommands {
    FrontendNodes,
    KubernetesNodes,
    Inventory,
}

#[derive(Subcommand, Debug)]
pub enum MigrateCommands {
    Release,
}

#[derive(Subcommand, Debug)]
pub enum VaultCommands {
    Init,
}

#[derive(Subcommand, Debug)]
pub enum KubernetesCommands {
    Init(KubernetesInitArgs),
}

#[derive(Args, Debug)]
pub struct KubernetesInitArgs {
    #[arg(short, long)]
    super_admin: bool,
}

#[derive(Subcommand, Debug)]
pub enum TestsCommands {
    All,
}

#[derive(Subcommand, Debug)]
pub enum ConnectionCommands {
    Up,
}
