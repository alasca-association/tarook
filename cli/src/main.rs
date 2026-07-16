use crate::commands::*;
use crate::errors::BashScriptError;
use anyhow::{Context, Result};
use clap::Parser;
use std::path::PathBuf;
use std::process::Command;
use std::process::Stdio;

pub mod commands;
pub mod errors;

#[derive(Parser)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    /// The cluster repository on which to operate
    #[arg(long, env = "TAROOK_CLUSTER_REPO", default_value = ".")]
    cluster_repo: std::path::PathBuf,
    /// The path to the repository containing the Tarook codebase.
    /// Default to $TAROOK_CLUSTER_REPO/managed-k8s
    #[arg(long, env = "TAROOK_CODE_PATH")]
    code_path: Option<std::path::PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

/// Runs an external command given a working directory and a path.
///
/// Returns an error if the status code is not 0.
///
/// This function should be deleted in the future as all functionality should be moved from the
/// shell scripts to Rust.
///
/// # Examples
///
/// ```
/// run_external_command(&cluster_repo, &tarook_module_dir.join("test.sh")).into()
/// ```
fn run_external_command(
    working_dir: &PathBuf,
    path: &PathBuf,
    args: &impl Arguments,
) -> Result<()> {
    // https://stackoverflow.com/questions/31992237/how-would-you-stream-output-from-a-process
    let mut cmd = Command::new(path)
        .current_dir(working_dir)
        .args(args.to_arg_vec())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .with_context(|| format!("Failed to spawn {path:?}"))?;

    let path = path.to_str().expect("Invalid path");

    // It's streaming here

    // https://doc.rust-lang.org/std/process/struct.Child.html#method.wait
    let status = cmd.wait().expect("Command wasn't running for some reason");

    let Some(code) = status.code() else {
        return Err(BashScriptError::ExitedBySignalError {
            script: path.to_owned(),
        }
        .into());
    };

    println!("Exited with status code: {code}");
    match code {
        0 => Ok(()),
        n => Err(BashScriptError::NonZeroExitCodeError {
            script: path.to_owned(),
            exit_code: n,
        }
        .into()),
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let cluster_repo = &cli.cluster_repo;
    let tarook_module_dir = &cli
        .code_path
        .unwrap_or_else(|| cli.cluster_repo.join("managed-k8s"));

    match &cli.command {
        Commands::InitClusterRepo => run_external_command(
            cluster_repo,
            &tarook_module_dir.join("actions/init-cluster-repo.sh"),
            &cli.command,
        ),
        Commands::Apply(subcommand) => {
            println!("apply {:?}", subcommand);
            match &subcommand {
                ApplyCommands::All => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/apply-all.sh"),
                    subcommand,
                ),
                ApplyCommands::Terraform => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/apply-terraform.sh"),
                    subcommand,
                ),
                ApplyCommands::Gateway => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/apply-prepare-gateways.sh"),
                    subcommand,
                ),
                ApplyCommands::Core(_) => {
                    // TODO: I'm sure there is a better way to do that but at least that makes the
                    // borrow checker happy for now.
                    run_external_command(
                        cluster_repo,
                        &tarook_module_dir.join("actions/apply-k8s-core.sh"),
                        subcommand,
                    )
                }
                ApplyCommands::Supplements(_) => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/apply-k8s-supplements.sh"),
                    subcommand,
                ),
                ApplyCommands::Custom => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/apply-custom.sh"),
                    subcommand,
                ),
            }
        }
        Commands::Update(subcommand) => {
            println!("update {:?}", subcommand);
            match &subcommand {
                UpdateCommands::FrontendNodes => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/update-frontend-nodes.sh"),
                    subcommand,
                ),
                UpdateCommands::KubernetesNodes => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/update-kubernetes-nodes.sh"),
                    subcommand,
                ),
                UpdateCommands::Inventory => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("actions/update-inventory.sh"),
                    subcommand,
                ),
            }
        }
        Commands::Upgrade(args) => {
            println!("upgrade");
            run_external_command(
                cluster_repo,
                &tarook_module_dir.join("actions/upgrade.sh"),
                args,
            )
        }
        Commands::MigrateToRelease => {
            println!("migrate");
            run_external_command(
                cluster_repo,
                &tarook_module_dir.join("actions/migrate-to-release.sh"),
                &cli.command,
            )
        }
        Commands::Vault(subcommand) => {
            println!("vault {:?}", subcommand);
            match &subcommand {
                VaultCommands::Init => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/init.sh"),
                    subcommand,
                ),
                VaultCommands::Import => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/import.sh"),
                    subcommand,
                ),
                VaultCommands::LoadSignedIntermediates => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/load-signed-intermediates.sh"),
                    subcommand,
                ),
                VaultCommands::MkClusterIntermediate => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/mkcluster-intermediate.sh"),
                    subcommand,
                ),
                VaultCommands::MkClusterRoot => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/mkcluster-root.sh"),
                    subcommand,
                ),
                VaultCommands::MkCsrs => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/mkcsrs.sh"),
                    subcommand,
                ),
                VaultCommands::RmCluster => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/rmcluster.sh"),
                    subcommand,
                ),
                VaultCommands::RotateRootCaIntermediate => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/rotate-root-ca-intermediate.sh"),
                    subcommand,
                ),
                VaultCommands::RotateRootCaRoot => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/rotate-root-ca-root.sh"),
                    subcommand,
                ),
                VaultCommands::Update => run_external_command(
                    cluster_repo,
                    &tarook_module_dir.join("tools/vault/update.sh"),
                    subcommand,
                ),
            }
        }
        Commands::K8sLogin(args) => run_external_command(
            cluster_repo,
            &tarook_module_dir.join("actions/k8s-login.sh"),
            args,
        ),
        Commands::Tests => run_external_command(
            cluster_repo,
            &tarook_module_dir.join("actions/tests.sh"),
            &cli.command,
        ),
        Commands::Wireguard(subcommand) => match &subcommand {
            WireguardCommands::Up => run_external_command(
                cluster_repo,
                &tarook_module_dir.join("actions/wg-up.sh"),
                subcommand,
            ),
        },
    }
}

// #[cfg(test)]
// mod tests {
//     use super::*;
//
//     #[test]
//     fn run_external_command_should_fail_when_script_doesnt_exist() {
//         println!("{:?}", run_external_command(&PathBuf::from("./"), &PathBuf::from("thisdoesnotexist.sh"), []));
//         assert_eq!(
//             // TODO: This can't be the idiomatic way to do this.
//             run_external_command(&PathBuf::from("./"), &PathBuf::from("thisdoesnotexist.sh"), []).unwrap_err().downcast_ref::<BashScriptError>().expect("Not a BashScriptError"),
//             &BashScriptError::NonZeroExitCodeError {
//                 script: "thisdoesnotexist.sh".to_owned(),
//                 exit_code: 127
//             }
//         )
//     }
// }
