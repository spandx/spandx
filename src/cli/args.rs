use camino::Utf8PathBuf;
use clap::{Parser, Subcommand, ValueEnum};

#[derive(Parser)]
#[command(
    name = "spandx",
    version = env!("CARGO_PKG_VERSION"),
    about = "A Rust interface to the SPDX catalogue for dependency license scanning",
    long_about = None,
    author = "Can Eldem <eldemcan@gmail.com>, mo khan <mo@mokhan.ca>"
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Scan a lockfile and list dependencies/licenses
    Scan {
        /// Path to the lockfile or directory to scan
        #[arg(default_value = ".")]
        path: Utf8PathBuf,

        /// Perform recursive directory scanning
        #[arg(short = 'R', long = "recursive")]
        recursive: bool,

        /// Disable network connections (air-gap mode)
        #[arg(short = 'a', long = "airgap")]
        airgap: bool,

        /// Path to a logfile
        #[arg(short = 'l', long = "logfile", default_value = "/dev/null")]
        logfile: Utf8PathBuf,

        /// Format of report (table, csv, json)
        #[arg(short = 'f', long = "format", default_value = "table")]
        format: OutputFormat,

        /// Pull the latest cache before the scan
        #[arg(short = 'p', long = "pull")]
        pull: bool,

        /// Load additional modules (for extensibility)
        #[arg(short = 'r', long = "require")]
        require: Option<String>,
    },

    /// Pull the latest offline cache
    Pull,

    /// Build a package index
    Build {
        /// Directory to build index in
        #[arg(short = 'd', long = "directory", default_value = ".index")]
        directory: Utf8PathBuf,

        /// Path to a logfile
        #[arg(short = 'l', long = "logfile", default_value = "/dev/null")]
        logfile: Utf8PathBuf,

        /// The specific index to build
        #[arg(short = 'i', long = "index", default_value = "all")]
        index: String,
    },

    /// Display version information
    Version,
}

#[derive(ValueEnum, Clone, Debug)]
pub enum OutputFormat {
    Table,
    Csv,
    Json,
}

impl std::fmt::Display for OutputFormat {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OutputFormat::Table => write!(f, "table"),
            OutputFormat::Csv => write!(f, "csv"),
            OutputFormat::Json => write!(f, "json"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::Parser;

    #[test]
    fn test_cli_scan_default() {
        let cli = Cli::parse_from(&["spandx", "scan"]);
        
        if let Commands::Scan { 
            path, 
            recursive, 
            airgap, 
            format, 
            pull, 
            .. 
        } = cli.command {
            assert_eq!(path.as_str(), ".");
            assert!(!recursive);
            assert!(!airgap);
            assert!(matches!(format, OutputFormat::Table));
            assert!(!pull);
        } else {
            panic!("Expected scan command");
        }
    }

    #[test]
    fn test_cli_scan_with_options() {
        let cli = Cli::parse_from(&[
            "spandx", 
            "scan", 
            "Gemfile.lock",
            "--recursive",
            "--airgap", 
            "--format", 
            "json",
            "--pull"
        ]);
        
        if let Commands::Scan { 
            path, 
            recursive, 
            airgap, 
            format, 
            pull, 
            .. 
        } = cli.command {
            assert_eq!(path.as_str(), "Gemfile.lock");
            assert!(recursive);
            assert!(airgap);
            assert!(matches!(format, OutputFormat::Json));
            assert!(pull);
        } else {
            panic!("Expected scan command");
        }
    }

    #[test]
    fn test_cli_pull() {
        let cli = Cli::parse_from(&["spandx", "pull"]);
        assert!(matches!(cli.command, Commands::Pull));
    }

    #[test]
    fn test_cli_build() {
        let cli = Cli::parse_from(&["spandx", "build"]);
        
        if let Commands::Build { directory, index, .. } = cli.command {
            assert_eq!(directory.as_str(), ".index");
            assert_eq!(index, "all");
        } else {
            panic!("Expected build command");
        }
    }

    #[test]
    fn test_cli_version() {
        let cli = Cli::parse_from(&["spandx", "version"]);
        assert!(matches!(cli.command, Commands::Version));
    }

    #[test]
    fn test_output_format_display() {
        assert_eq!(format!("{}", OutputFormat::Table), "table");
        assert_eq!(format!("{}", OutputFormat::Csv), "csv");
        assert_eq!(format!("{}", OutputFormat::Json), "json");
    }
}