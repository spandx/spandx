use anyhow::Result;

pub struct VersionCommand;

impl VersionCommand {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(&self) -> Result<()> {
        println!("v{}", env!("CARGO_PKG_VERSION"));
        Ok(())
    }

    pub fn version_info() -> VersionInfo {
        VersionInfo {
            version: env!("CARGO_PKG_VERSION").to_string(),
            commit: option_env!("GIT_COMMIT").unwrap_or("unknown").to_string(),
            build_date: option_env!("BUILD_DATE").unwrap_or("unknown").to_string(),
            target: std::env::var("TARGET").unwrap_or_else(|_| "unknown".to_string()),
            rust_version: std::env::var("RUST_VERSION").unwrap_or_else(|_| "unknown".to_string()),
        }
    }

    pub async fn execute_detailed(&self) -> Result<()> {
        let info = Self::version_info();
        println!("spandx {}", info.version);
        println!("commit: {}", info.commit);
        println!("build date: {}", info.build_date);
        println!("target: {}", info.target);
        println!("rust version: {}", info.rust_version);
        Ok(())
    }
}

impl Default for VersionCommand {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone)]
pub struct VersionInfo {
    pub version: String,
    pub commit: String,
    pub build_date: String,
    pub target: String,
    pub rust_version: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_version_command() {
        let cmd = VersionCommand::new();
        let result = cmd.execute().await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_version_command_detailed() {
        let cmd = VersionCommand::new();
        let result = cmd.execute_detailed().await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_version_info() {
        let info = VersionCommand::version_info();
        assert!(!info.version.is_empty());
        assert!(!info.target.is_empty());
        assert!(!info.rust_version.is_empty());
    }

    #[test]
    fn test_version_command_default() {
        let cmd = VersionCommand::default();
        // Just ensure we can create the command with default
        assert!(true);
    }
}