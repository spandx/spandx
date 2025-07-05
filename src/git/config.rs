use anyhow::Result;
use camino::Utf8PathBuf;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Configuration for Git repositories
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GitConfig {
    pub repositories: HashMap<String, RepositoryConfig>,
    pub base_path: Option<Utf8PathBuf>,
    pub default_branch: String,
    pub shallow_clone: bool,
    pub fetch_depth: i32,
}

impl Default for GitConfig {
    fn default() -> Self {
        let mut repositories = HashMap::new();
        
        repositories.insert(
            "cache".to_string(),
            RepositoryConfig {
                url: "https://github.com/spandx/cache.git".to_string(),
                branch: Some("main".to_string()),
                enabled: true,
                description: Some("Pre-computed license cache".to_string()),
            },
        );
        
        repositories.insert(
            "rubygems".to_string(),
            RepositoryConfig {
                url: "https://github.com/spandx/rubygems-cache.git".to_string(),
                branch: Some("main".to_string()),
                enabled: true,
                description: Some("RubyGems specific license cache".to_string()),
            },
        );
        
        repositories.insert(
            "spdx".to_string(),
            RepositoryConfig {
                url: "https://github.com/spdx/license-list-data.git".to_string(),
                branch: Some("main".to_string()),
                enabled: true,
                description: Some("SPDX license list data".to_string()),
            },
        );
        
        Self {
            repositories,
            base_path: None,
            default_branch: "main".to_string(),
            shallow_clone: true,
            fetch_depth: 1,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RepositoryConfig {
    pub url: String,
    pub branch: Option<String>,
    pub enabled: bool,
    pub description: Option<String>,
}

impl GitConfig {
    /// Load configuration from file
    pub async fn load_from_file<P: AsRef<std::path::Path>>(path: P) -> Result<Self> {
        let content = tokio::fs::read_to_string(path).await?;
        let config: GitConfig = toml::from_str(&content)?;
        Ok(config)
    }
    
    /// Save configuration to file
    pub async fn save_to_file<P: AsRef<std::path::Path>>(&self, path: P) -> Result<()> {
        let content = toml::to_string_pretty(self)?;
        
        // Ensure parent directory exists
        if let Some(parent) = path.as_ref().parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        tokio::fs::write(path, content).await?;
        Ok(())
    }
    
    /// Get base path for repositories
    pub fn get_base_path(&self) -> Result<Utf8PathBuf> {
        if let Some(base_path) = &self.base_path {
            Ok(base_path.clone())
        } else {
            // Default to ~/.local/share/spandx
            let home_dir = dirs::home_dir()
                .ok_or_else(|| anyhow::anyhow!("Could not determine home directory"))?;
            
            let base_path = Utf8PathBuf::from_path_buf(home_dir)
                .map_err(|_| anyhow::anyhow!("Invalid UTF-8 in home directory path"))?
                .join(".local")
                .join("share")
                .join("spandx");
            
            Ok(base_path)
        }
    }
    
    /// Get local path for a repository
    pub fn get_repository_path(&self, repo_name: &str) -> Result<Utf8PathBuf> {
        let base_path = self.get_base_path()?;
        Ok(base_path.join(repo_name))
    }
    
    /// Get branch for a repository (with fallback to default)
    pub fn get_repository_branch(&self, repo_name: &str) -> String {
        self.repositories
            .get(repo_name)
            .and_then(|config| config.branch.as_ref())
            .unwrap_or(&self.default_branch)
            .clone()
    }
    
    /// Check if a repository is enabled
    pub fn is_repository_enabled(&self, repo_name: &str) -> bool {
        self.repositories
            .get(repo_name)
            .map(|config| config.enabled)
            .unwrap_or(false)
    }
    
    /// Get all enabled repositories
    pub fn get_enabled_repositories(&self) -> Vec<String> {
        self.repositories
            .iter()
            .filter(|(_, config)| config.enabled)
            .map(|(name, _)| name.clone())
            .collect()
    }
    
    /// Add or update a repository
    pub fn add_repository(&mut self, name: String, config: RepositoryConfig) {
        self.repositories.insert(name, config);
    }
    
    /// Remove a repository
    pub fn remove_repository(&mut self, name: &str) -> Option<RepositoryConfig> {
        self.repositories.remove(name)
    }
    
    /// Enable or disable a repository
    pub fn set_repository_enabled(&mut self, name: &str, enabled: bool) -> Result<()> {
        if let Some(config) = self.repositories.get_mut(name) {
            config.enabled = enabled;
            Ok(())
        } else {
            Err(anyhow::anyhow!("Repository not found: {}", name))
        }
    }
    
    /// Validate configuration
    pub fn validate(&self) -> Result<()> {
        // Check that base path is valid if specified
        if let Some(base_path) = &self.base_path {
            if !base_path.is_absolute() {
                return Err(anyhow::anyhow!("Base path must be absolute: {}", base_path));
            }
        }
        
        // Validate repository URLs
        for (name, config) in &self.repositories {
            if config.url.is_empty() {
                return Err(anyhow::anyhow!("Repository {} has empty URL", name));
            }
            
            // Basic URL validation
            if !config.url.starts_with("http://") && !config.url.starts_with("https://") {
                return Err(anyhow::anyhow!("Repository {} has invalid URL: {}", name, config.url));
            }
        }
        
        // Check fetch depth
        if self.fetch_depth <= 0 {
            return Err(anyhow::anyhow!("Fetch depth must be positive: {}", self.fetch_depth));
        }
        
        Ok(())
    }
    
    /// Create repositories from this configuration
    pub fn create_repositories(&self) -> Result<HashMap<String, crate::git::GitRepository>> {
        self.validate()?;
        
        let mut repositories = HashMap::new();
        
        for (name, config) in &self.repositories {
            if !config.enabled {
                continue;
            }
            
            let local_path = self.get_repository_path(name)?;
            let branch = self.get_repository_branch(name);
            
            let repo = crate::git::GitRepository::new(
                config.url.clone(),
                branch,
                local_path,
            );
            
            repositories.insert(name.clone(), repo);
        }
        
        Ok(repositories)
    }
}

/// Get default configuration file path
pub fn get_default_config_path() -> Result<Utf8PathBuf> {
    let home_dir = dirs::home_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not determine home directory"))?;
    
    let config_path = Utf8PathBuf::from_path_buf(home_dir)
        .map_err(|_| anyhow::anyhow!("Invalid UTF-8 in home directory path"))?
        .join(".config")
        .join("spandx")
        .join("git.toml");
    
    Ok(config_path)
}

/// Load configuration with fallback to defaults
pub async fn load_config_with_defaults() -> Result<GitConfig> {
    let config_path = get_default_config_path()?;
    
    if config_path.exists() {
        match GitConfig::load_from_file(&config_path).await {
            Ok(config) => {
                config.validate()?;
                Ok(config)
            }
            Err(e) => {
                tracing::warn!("Failed to load Git config from {:?}: {}", config_path, e);
                tracing::info!("Using default configuration");
                Ok(GitConfig::default())
            }
        }
    } else {
        tracing::debug!("No Git config file found at {:?}, using defaults", config_path);
        Ok(GitConfig::default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_default_config() {
        let config = GitConfig::default();
        
        assert_eq!(config.default_branch, "main");
        assert!(config.shallow_clone);
        assert_eq!(config.fetch_depth, 1);
        assert_eq!(config.repositories.len(), 3);
        
        // Check that required repositories exist
        assert!(config.repositories.contains_key("cache"));
        assert!(config.repositories.contains_key("rubygems"));
        assert!(config.repositories.contains_key("spdx"));
        
        // Check that all are enabled by default
        assert!(config.is_repository_enabled("cache"));
        assert!(config.is_repository_enabled("rubygems"));
        assert!(config.is_repository_enabled("spdx"));
    }
    
    #[test]
    fn test_repository_management() {
        let mut config = GitConfig::default();
        
        // Test adding a repository
        config.add_repository(
            "test".to_string(),
            RepositoryConfig {
                url: "https://github.com/test/repo.git".to_string(),
                branch: Some("develop".to_string()),
                enabled: true,
                description: Some("Test repository".to_string()),
            },
        );
        
        assert!(config.repositories.contains_key("test"));
        assert!(config.is_repository_enabled("test"));
        assert_eq!(config.get_repository_branch("test"), "develop");
        
        // Test disabling a repository
        config.set_repository_enabled("test", false).unwrap();
        assert!(!config.is_repository_enabled("test"));
        
        // Test removing a repository
        let removed = config.remove_repository("test");
        assert!(removed.is_some());
        assert!(!config.repositories.contains_key("test"));
    }
    
    #[tokio::test]
    async fn test_config_file_operations() {
        let temp_dir = TempDir::new().unwrap();
        let config_path = temp_dir.path().join("git.toml");
        
        let original_config = GitConfig::default();
        
        // Save config
        original_config.save_to_file(&config_path).await.unwrap();
        assert!(config_path.exists());
        
        // Load config
        let loaded_config = GitConfig::load_from_file(&config_path).await.unwrap();
        
        // Compare key fields
        assert_eq!(loaded_config.default_branch, original_config.default_branch);
        assert_eq!(loaded_config.shallow_clone, original_config.shallow_clone);
        assert_eq!(loaded_config.fetch_depth, original_config.fetch_depth);
        assert_eq!(loaded_config.repositories.len(), original_config.repositories.len());
    }
    
    #[test]
    fn test_config_validation() {
        let mut config = GitConfig::default();
        
        // Valid config should pass
        assert!(config.validate().is_ok());
        
        // Invalid fetch depth should fail
        config.fetch_depth = 0;
        assert!(config.validate().is_err());
        config.fetch_depth = 1;
        
        // Invalid URL should fail
        config.add_repository(
            "invalid".to_string(),
            RepositoryConfig {
                url: "not-a-url".to_string(),
                branch: None,
                enabled: true,
                description: None,
            },
        );
        assert!(config.validate().is_err());
    }
}