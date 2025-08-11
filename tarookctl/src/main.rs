use clap::{Args, Parser, Subcommand};
use std::process::Command;
use std::process::Stdio;

#[derive(Parser)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
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
enum InitCommands {
    Git,
}

#[derive(Subcommand, Debug)]
enum ApplyCommands {
    All,
    Terraform,
    Gateway,
    Custom,
    Supplements,
}

#[derive(Subcommand, Debug)]
enum UpdateCommands {
    FrontendNodes,
    KubernetesNodes,
    Inventory,
}

#[derive(Subcommand, Debug)]
enum MigrateCommands {
    Release,
}

#[derive(Subcommand, Debug)]
enum VaultCommands {
    Init,
}

#[derive(Subcommand, Debug)]
enum KubernetesCommands {
    Init(KubernetesInitArgs),
}

#[derive(Args, Debug)]
struct KubernetesInitArgs {
    #[arg(short, long)]
    super_admin: bool,
}

#[derive(Subcommand, Debug)]
enum TestsCommands {
    All,
}

#[derive(Subcommand, Debug)]
enum ConnectionCommands {
    Up,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Init(subcommand) => {
            println!("init {:?}", subcommand);
        }
        Commands::Apply(subcommand) => {
            println!("apply {:?}", subcommand);
            match &subcommand {
                ApplyCommands::All {} => {
                    // https://stackoverflow.com/questions/31992237/how-would-you-stream-output-from-a-process
                    let mut cmd = Command::new("bash")
                        .arg("apply.sh")
                        .stdout(Stdio::inherit())
                        .stderr(Stdio::inherit())
                        .spawn()
                        .expect("Failed to execute command");

                    // It's streaming here
                    let status = cmd.wait();
                    println!("Exited with status {:?}", status);
                }
                _ => {}
            }
        }
        Commands::Update(subcommand) => {
            println!("update {:?}", subcommand);
        }
        Commands::Upgrade {} => {
            println!("upgrade");
        }
        Commands::Migrate(subcommand) => {
            println!("migrate {:?}", subcommand);
        }
        Commands::Vault(subcommand) => {
            println!("vault {:?}", subcommand);
        }
        Commands::Kubernetes(subcommand) => {
            println!("kubernetes {:?}", subcommand);
        }
        Commands::Tests(subcommand) => {
            println!("tests {:?}", subcommand);
        }
        Commands::Connection(subcommand) => {
            println!("kubernetes {:?}", subcommand);
        }
        Commands::Ssh {} => {
            println!("ssh");
        }
    }
}
