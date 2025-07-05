use anyhow::Result;
use camino::Utf8PathBuf;
use tracing::{info, warn};

use crate::cache::{CacheManager, IndexBuilder};

pub struct BuildCommand {
    pub directory: Utf8PathBuf,
    pub index: String,
}

impl BuildCommand {
    pub fn new(directory: Utf8PathBuf, index: String) -> Self {
        Self { directory, index }
    }

    pub async fn execute(&self) -> Result<()> {
        info!("Building package index in: {}", self.directory);
        info!("Index type: {}", self.index);

        // Ensure directory exists
        if !self.directory.exists() {
            tokio::fs::create_dir_all(&self.directory).await?;
        }

        let cache_manager = CacheManager::new().await?;
        let index_builder = IndexBuilder::new(&self.directory);

        match self.index.as_str() {
            "all" => {
                info!("Building all indices...");
                self.build_all_indices(&index_builder, &cache_manager).await?;
            }
            "rubygems" | "ruby" => {
                info!("Building Ruby gems index...");
                index_builder.build_rubygems_index(&cache_manager).await?;
            }
            "npm" | "javascript" | "js" => {
                info!("Building NPM index...");
                index_builder.build_npm_index(&cache_manager).await?;
            }
            "pypi" | "python" => {
                info!("Building PyPI index...");
                index_builder.build_pypi_index(&cache_manager).await?;
            }
            "nuget" | "dotnet" => {
                info!("Building NuGet index...");
                index_builder.build_nuget_index(&cache_manager).await?;
            }
            "maven" | "java" => {
                info!("Building Maven index...");
                index_builder.build_maven_index(&cache_manager).await?;
            }
            "packagist" | "php" => {
                info!("Building Packagist index...");
                index_builder.build_packagist_index(&cache_manager).await?;
            }
            "spdx" => {
                info!("Building SPDX license index...");
                index_builder.build_spdx_index(&cache_manager).await?;
            }
            unknown => {
                return Err(anyhow::anyhow!("Unknown index type: {}", unknown));
            }
        }

        info!("Index building complete");
        Ok(())
    }

    async fn build_all_indices(
        &self,
        index_builder: &IndexBuilder<'_>,
        cache_manager: &CacheManager,
    ) -> Result<()> {
        let indices = [
            ("SPDX", "spdx"),
            ("Ruby gems", "rubygems"),
            ("NPM", "npm"),
            ("PyPI", "pypi"),
            ("NuGet", "nuget"),
            ("Maven", "maven"),
            ("Packagist", "packagist"),
        ];

        for (name, index_type) in &indices {
            info!("Building {} index...", name);
            
            let result = match *index_type {
                "spdx" => index_builder.build_spdx_index(cache_manager).await,
                "rubygems" => index_builder.build_rubygems_index(cache_manager).await,
                "npm" => index_builder.build_npm_index(cache_manager).await,
                "pypi" => index_builder.build_pypi_index(cache_manager).await,
                "nuget" => index_builder.build_nuget_index(cache_manager).await,
                "maven" => index_builder.build_maven_index(cache_manager).await,
                "packagist" => index_builder.build_packagist_index(cache_manager).await,
                _ => unreachable!(),
            };

            if let Err(e) = result {
                warn!("Failed to build {} index: {}", name, e);
            } else {
                info!("Successfully built {} index", name);
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_build_command_creation() {
        let cmd = BuildCommand::new(".index".into(), "all".to_string());
        assert_eq!(cmd.directory.as_str(), ".index");
        assert_eq!(cmd.index, "all");
    }

    #[tokio::test]
    async fn test_build_command_unknown_index() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = Utf8PathBuf::try_from(temp_dir.path().to_path_buf()).unwrap();
        
        let cmd = BuildCommand::new(temp_path, "unknown".to_string());
        let result = cmd.execute().await;
        
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Unknown index type"));
    }

    #[test]
    fn test_valid_index_types() {
        let valid_types = [
            "all", "rubygems", "ruby", "npm", "javascript", "js",
            "pypi", "python", "nuget", "dotnet", "maven", "java",
            "packagist", "php", "spdx"
        ];

        for index_type in &valid_types {
            let cmd = BuildCommand::new(".index".into(), index_type.to_string());
            assert_eq!(cmd.index, *index_type);
        }
    }
}