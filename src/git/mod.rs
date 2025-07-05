pub mod repository;
pub mod operations;
pub mod config;

pub use repository::GitRepository;
pub use operations::GitOperations;
pub use config::GitConfig;

use anyhow::Result;
use camino::Utf8PathBuf;
use std::collections::HashMap;

/// Initialize default Git repositories for Spandx
pub fn init_default_repositories() -> Result<HashMap<String, GitRepository>> {
    let mut repos = HashMap::new();
    
    // Cache repository for pre-computed license data
    repos.insert(
        "cache".to_string(),
        GitRepository::new(
            "https://github.com/spandx/cache.git".to_string(),
            "main".to_string(),
            get_local_path("cache")?,
        ),
    );
    
    // RubyGems-specific cache repository
    repos.insert(
        "rubygems".to_string(),
        GitRepository::new(
            "https://github.com/spandx/rubygems-cache.git".to_string(),
            "main".to_string(),
            get_local_path("rubygems-cache")?,
        ),
    );
    
    // SPDX license list data
    repos.insert(
        "spdx".to_string(),
        GitRepository::new(
            "https://github.com/spdx/license-list-data.git".to_string(),
            "main".to_string(),
            get_local_path("spdx-license-list-data")?,
        ),
    );
    
    Ok(repos)
}

/// Get local storage path for a repository
fn get_local_path(repo_name: &str) -> Result<Utf8PathBuf> {
    let home_dir = dirs::home_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not determine home directory"))?;
    
    let local_path = Utf8PathBuf::from_path_buf(home_dir)
        .map_err(|_| anyhow::anyhow!("Invalid UTF-8 in home directory path"))?
        .join(".local")
        .join("share")
        .join("spandx")
        .join(repo_name);
    
    Ok(local_path)
}

/// Update all repositories and rebuild cache indices
pub async fn sync_repositories(repos: &mut HashMap<String, GitRepository>) -> Result<()> {
    use tracing::{info, warn};
    
    info!("Syncing Git repositories...");
    
    // Update all repositories in parallel
    let futures: Vec<_> = repos.values_mut().map(|repo| async move {
        match repo.update().await {
            Ok(_) => {
                info!("Successfully updated repository: {}", repo.name());
                Ok(())
            }
            Err(e) => {
                warn!("Failed to update repository {}: {}", repo.name(), e);
                Err(e)
            }
        }
    }).collect();
    
    // Wait for all repositories to complete
    let results = futures::future::join_all(futures).await;
    
    // Check if any updates failed
    let mut errors = Vec::new();
    for result in results {
        if let Err(e) = result {
            errors.push(e);
        }
    }
    
    if !errors.is_empty() {
        warn!("Some repositories failed to update: {} errors", errors.len());
        // Continue with cache rebuild even if some repositories failed
    }
    
    info!("Repository sync completed");
    Ok(())
}