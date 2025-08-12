use crate::commands::*;
use crate::errors::BashScriptError;
use clap::Parser;
use std::process::Command;
use std::process::Stdio;

pub mod commands;
pub mod errors;

#[derive(Parser)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

/// Runs a bash script from a relative path.
///
/// Returns an error if the status code is not 0.
///
/// This function should be deleted in the future as all functionality should be moved from the
/// shell scripts to Rust.
///
/// # Examples
///
/// ```
/// run_bash_script("test.sh").expect("oh noez..!");
/// ```
fn run_bash_script(path: &str) -> Result<(), BashScriptError> {
    // https://stackoverflow.com/questions/31992237/how-would-you-stream-output-from-a-process
    let mut cmd = Command::new("bash")
        .arg(path)
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .expect("IO error");

    // It's streaming here

    let status = cmd.wait();

    if !status.as_ref().unwrap().success() {
        Err(BashScriptError::NonZeroExitCodeError {
            script: path.to_owned(),
            exit_code: status.as_ref().unwrap().code().expect("no exit code"),
        })
    } else {
        Ok(())
    }
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
                    run_bash_script("apply.sh").expect("oh noez..!");
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_bash_script_should_fail_when_script_doesnt_exist() {
        assert_eq!(
            run_bash_script("thisdoesnotexist.sh"),
            Err(BashScriptError::NonZeroExitCodeError {
                script: "thisdoesnotexist.sh".to_owned(),
                exit_code: 127
            })
        )
    }
}
