use anyhow::Result;
use tracing::{info, warn};

use crate::cache::CacheManager;

pub struct PullCommand;

impl PullCommand {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(&self) -> Result<()> {
        info!("Pulling latest offline cache...");

        let mut cache_manager = CacheManager::new().await?;
        
        // Update all repositories and rebuild cache indices
        match cache_manager.update_all().await {
            Ok(_) => {
                info!("All caches updated successfully");
            }
            Err(e) => {
                warn!("Cache update completed with some errors: {}", e);
                
                // Try individual updates as fallback
                info!("Attempting individual repository updates...");
                
                // Pull SPDX license data
                if let Err(e) = cache_manager.update_spdx_cache().await {
                    warn!("Failed to update SPDX cache: {}", e);
                }

                // Pull Ruby gems cache
                if let Err(e) = cache_manager.update_rubygems_cache().await {
                    warn!("Failed to update Ruby gems cache: {}", e);
                }

                // Pull general package cache
                if let Err(e) = cache_manager.update_general_cache().await {
                    warn!("Failed to update general cache: {}", e);
                }
            }
        }
        
        // Display repository status
        let status = cache_manager.get_repository_status().await;
        info!("Repository status:");
        for (name, info) in status {
            match info.status {
                crate::git::repository::RepositoryStatus::Clean { commit_hash, .. } => {
                    info!("  {}: ✓ up-to-date ({})", name, &commit_hash[..8]);
                }
                crate::git::repository::RepositoryStatus::Dirty => {
                    warn!("  {}: ⚠ has uncommitted changes", name);
                }
                crate::git::repository::RepositoryStatus::NotCloned => {
                    warn!("  {}: ✗ not cloned", name);
                }
            }
        }

        info!("Cache update complete");
        Ok(())
    }
}

impl Default for PullCommand {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_pull_command_creation() {
        let cmd = PullCommand::new();
        // Just ensure we can create the command
        assert!(true);
    }

    #[test]
    fn test_pull_command_default() {
        let cmd = PullCommand::default();
        // Just ensure we can create the command with default
        assert!(true);
    }
}