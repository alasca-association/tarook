/// Commands and subcommands for tarook
// If you want to add additional commands or subcommands, you also have to implement the Arguments
// trait for them. If your new command doesn't have any optional arguments, you can just use the
// default implementation.
use clap::{Args, Subcommand};

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize the cluster repository
    InitClusterRepo,
    /// Apply things
    #[command(subcommand)]
    Apply(ApplyCommands),
    /// Commands related to updating things
    #[command(subcommand)]
    Update(UpdateCommands),
    /// Upgrade the cluster's Kubernetes version
    Upgrade(UpgradeArgs),
    /// Migrate the cluster repository to the current major release
    MigrateToRelease,
    /// Commands related to the Vault secret backend
    #[command(subcommand)]
    Vault(VaultCommands),
    /// Create a kubeconfig for the cluster that is valid for one week
    K8sLogin(K8sLoginArgs),
    /// Run tests within the Kubernetes cluster
    Tests,
    /// Commands related to the wireguard connection
    #[command(subcommand)]
    Wireguard(WireguardCommands),
}

#[derive(Subcommand, Debug)]
pub enum ApplyCommands {
    /// Apply all stages
    All,
    /// Apply the Terraform stage
    Terraform,
    /// Apply the gateway nodes
    Gateway,
    /// Apply Tarook Core
    Core(ApplyArgs),
    /// Apply Tarook Supplements
    Supplements(ApplyArgs),
    /// Apply custom play
    Custom,
}

#[derive(Subcommand, Debug)]
pub enum UpdateCommands {
    /// Upgrade all Debian packages on the frontend nodes
    FrontendNodes,
    /// Upgrade all Ubuntu packages on the Kubernetes nodes
    KubernetesNodes,
    /// Update the inventory.
    /// This is run automatically by all dependent tasks
    Inventory,
}

#[derive(Subcommand, Debug)]
pub enum VaultCommands {
    /// Initialize the Vault backend
    Init,
    Import,
    LoadSignedIntermediates,
    /// Create the relevant paths and secrets in the Vault backend for a new cluster using an intermediate certificate
    MkClusterIntermediate,
    /// Create the relevant paths and secrets in the Vault backend for a new cluster using a root certificate
    MkClusterRoot,
    MkCsrs,
    /// Remove a cluster from the Vault backend
    RmCluster,
    RotateRootCaIntermediate,
    RotateRootCaRoot,
    Update,
}

#[derive(Args, Debug)]
pub struct ApplyArgs {
    /// Trigger specific playbook.
    /// Use "list" to list available playbooks.
    /// If not supplied, 'install-all.yaml' is triggered
    pub playbook: Option<String>,
}

#[derive(Args, Debug)]
pub struct UpgradeArgs {
    /// The Kubernetes version to upgrade to
    target_version: String,
}

#[derive(Args, Debug)]
pub struct K8sLoginArgs {
    /// Create the kubeconfig with super-admin permissions
    #[arg(short, long)]
    pub super_admin: bool,
}

#[derive(Subcommand, Debug)]
pub enum WireguardCommands {
    Up,
}

/// For commands that can have optional arguments.
pub trait Arguments {
    /// Return an vector argument if implemented and an empty vector otherwise.
    fn to_arg_vec(&self) -> Vec<String> {
        vec![]
    }
}

impl Arguments for Commands {
    fn to_arg_vec(&self) -> Vec<String> {
        match self {
            // For all commands without any optional arguments we can just return an empty vector
            Commands::InitClusterRepo => {
                vec![]
            }
            Commands::MigrateToRelease => {
                vec![]
            }
            Commands::Tests => {
                vec![]
            }
            // For all the commands with arguments or subcommands we rely on their implementation.
            other => other.to_arg_vec(),
        }
    }
}

impl Arguments for ApplyCommands {
    fn to_arg_vec(&self) -> Vec<String> {
        match self {
            ApplyCommands::Core(args) => match args.playbook.clone() {
                Some(arg) => {
                    vec![arg.to_owned()]
                }
                None => vec![],
            },
            ApplyCommands::Supplements(args) => match args.playbook.clone() {
                Some(arg) => {
                    vec![arg.to_owned()]
                }
                None => vec![],
            },
            // TODO: Implement other subcommands
            _ => vec![],
        }
    }
}

/// TODO: Implement!
impl Arguments for UpdateCommands {}

/// TODO: Implement!
impl Arguments for UpgradeArgs {}

/// TODO: Implement!
impl Arguments for VaultCommands {}

impl Arguments for K8sLoginArgs {
    fn to_arg_vec(&self) -> Vec<String> {
        if self.super_admin {
            vec!["-s".to_string()]
        } else {
            vec![]
        }
    }
}

/// TODO: Implement!
impl Arguments for WireguardCommands {}
