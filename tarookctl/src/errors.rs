use thiserror::Error;

#[derive(Error, Debug, PartialEq)]
pub enum BashScriptError {
    NonZeroExitCodeError { script: String, exit_code: i32 },
}

impl std::fmt::Display for BashScriptError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BashScriptError::NonZeroExitCodeError { script, exit_code } => {
                write!(f, "{} exited with {}", script, exit_code)
            }
        }
    }
}
