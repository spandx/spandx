use clap::Parser;
use std::process;
use tracing::{error, debug};

use spandx::{SpandxError, SpandxResult};
use spandx::cli::{Cli, Commands};
use spandx::cli::commands::{ScanCommand, PullCommand, BuildCommand, VersionCommand};

#[tokio::main]
async fn main() {
    if let Err(exit_code) = run().await {
        process::exit(exit_code);
    }
}

async fn run() -> Result<(), i32> {
    let cli = Cli::parse();

    // Initialize tracing based on log level
    spandx::init_tracing();

    let result: SpandxResult<()> = match cli.command {
        Commands::Scan { 
            path, 
            recursive, 
            airgap, 
            logfile: _,  // TODO: Use logfile for tracing configuration
            format, 
            pull, 
            require: _, // TODO: Implement module loading
        } => {
            let scan_cmd = ScanCommand::new(path, recursive, airgap, format, pull);
            scan_cmd.execute().await
        }

        Commands::Pull => {
            let pull_cmd = PullCommand::new();
            pull_cmd.execute().await.map_err(|e| e.into())
        }

        Commands::Build { 
            directory, 
            logfile: _, // TODO: Use logfile for tracing configuration
            index 
        } => {
            let build_cmd = BuildCommand::new(directory, index);
            build_cmd.execute().await.map_err(|e| e.into())
        }

        Commands::Version => {
            let version_cmd = VersionCommand::new();
            version_cmd.execute().await.map_err(|e| e.into())
        }
    };

    if let Err(e) = result {
        handle_error(&e)
    } else {
        Ok(())
    }
}

/// Enhanced error handling with user-friendly messages and proper exit codes
fn handle_error(error: &SpandxError) -> Result<(), i32> {
    // Log the full error for debugging
    debug!("Full error details: {:?}", error);
    
    // Display user-friendly error message
    eprintln!("Error: {}", error.user_message());
    
    // Show additional context for certain error types
    match error {
        SpandxError::FileNotFound { path } => {
            eprintln!("  The file '{}' could not be found.", path);
            eprintln!("  Please check the path and try again.");
        }
        SpandxError::DirectoryNotFound { path } => {
            eprintln!("  The directory '{}' could not be found.", path);
            eprintln!("  Please check the path and try again.");
        }
        SpandxError::PermissionDenied { path } => {
            eprintln!("  Permission denied accessing '{}'.", path);
            eprintln!("  Please check file permissions and try again.");
        }
        SpandxError::NetworkError { url, .. } => {
            eprintln!("  Failed to access: {}", url);
            eprintln!("  Please check your internet connection and try again.");
            if error.is_retriable() {
                if let Some(retry_ms) = error.retry_delay_ms() {
                    eprintln!("  You can retry after {} seconds.", retry_ms / 1000);
                }
            }
        }
        SpandxError::PackageNotFound { package, version, registry } => {
            eprintln!("  Package '{}@{}' not found in {}.", package, version, registry);
            eprintln!("  Please verify the package name and version.");
        }
        SpandxError::InvalidArguments { .. } => {
            eprintln!("  Use --help for usage information.");
        }
        SpandxError::ConfigError { .. } => {
            eprintln!("  Check your configuration and try again.");
        }
        SpandxError::NotImplemented { feature } => {
            eprintln!("  The feature '{}' is not yet implemented.", feature);
            eprintln!("  Please check the documentation for supported features.");
        }
        _ => {
            // For other errors, show category and suggest actions
            eprintln!("  Category: {}", error.category());
            
            if error.is_retriable() {
                eprintln!("  This error may be temporary. You can try again.");
            } else {
                eprintln!("  Please check the error details and fix any issues.");
            }
        }
    }
    
    // Return appropriate exit code
    let exit_code = match error.category() {
        spandx::error::ErrorCategory::Cli => 2,        // Invalid usage
        spandx::error::ErrorCategory::FileSystem => 3,  // File system issues
        spandx::error::ErrorCategory::Network => 4,     // Network issues
        spandx::error::ErrorCategory::Parse => 5,       // Parse errors
        spandx::error::ErrorCategory::Config => 6,      // Configuration errors
        _ => 1,                                          // General error
    };
    
    error!("Command failed with error category: {} (exit code: {})", error.category(), exit_code);
    Err(exit_code)
}

#[cfg(test)]
mod tests {
    use super::*;
    use assert_cmd::Command;
    use predicates::prelude::*;

    #[test]
    fn test_version_command() {
        let mut cmd = Command::cargo_bin("spandx").unwrap();
        cmd.arg("version");
        
        cmd.assert()
            .success()
            .stdout(predicate::str::starts_with("v"));
    }

    #[test]
    fn test_help_command() {
        let mut cmd = Command::cargo_bin("spandx").unwrap();
        cmd.arg("--help");
        
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("spandx"))
            .stdout(predicate::str::contains("Rust interface to the SPDX catalogue"));
    }

    #[test]
    fn test_scan_help() {
        let mut cmd = Command::cargo_bin("spandx").unwrap();
        cmd.args(&["scan", "--help"]);
        
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Scan a lockfile"));
    }

    #[test]
    fn test_pull_help() {
        let mut cmd = Command::cargo_bin("spandx").unwrap();
        cmd.args(&["pull", "--help"]);
        
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Pull the latest offline cache"));
    }

    #[test]
    fn test_build_help() {
        let mut cmd = Command::cargo_bin("spandx").unwrap();
        cmd.args(&["build", "--help"]);
        
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Build a package index"));
    }
}
