use crate::error::{SpandxError, SpandxResult};
use tracing::{info, warn};

use crate::cache::{Cache, CacheStats, MemoryCacheStats};
use crate::git::GitOperations;

pub struct CacheManager {
    git_operations: GitOperations,
    cache: Cache,
}

impl CacheManager {
    pub async fn new() -> SpandxResult<Self> {
        // Load Git configuration
        let git_config = crate::git::config::load_config_with_defaults().await?;
        
        // Create repositories from configuration
        let repositories = git_config.create_repositories()?;
        let git_operations = GitOperations::new(repositories);
        
        // Initialize hierarchical cache with reasonable memory cache size
        let cache_dir = git_config.get_base_path()?.join("cache");
        let cache = Cache::with_memory_cache_size(cache_dir, 5000); // 5000 entries in L1 cache
        
        Ok(Self {
            git_operations,
            cache,
        })
    }
    
    /// Update all Git repositories and rebuild cache indices
    pub async fn update_all(&mut self) -> SpandxResult<()> {
        info!("Starting comprehensive cache update...");
        
        // Update all Git repositories
        let update_result = self.git_operations.update_all().await?;
        
        if !update_result.is_success() {
            warn!("Some repositories failed to update:");
            for (repo, error) in &update_result.failed {
                warn!("  {}: {}", repo, error);
            }
            
            if update_result.successful.is_empty() {
                return Err(SpandxError::GitError {
                    operation: "update_all".to_string(),
                    repository: "multiple".to_string(),
                    source: git2::Error::from_str("All repository updates failed"),
                });
            }
        }
        
        info!("Successfully updated {} repositories", update_result.successful.len());
        
        // Rebuild cache indices from updated repositories
        let build_result = self.git_operations.build_cache_indices(&mut self.cache).await?;
        
        if !build_result.is_success() {
            warn!("Some cache builds failed:");
            for (repo, error) in &build_result.errors {
                warn!("  {}: {}", repo, error);
            }
        }
        
        info!("Cache update complete. Total entries: {}", build_result.total_entries());
        Ok(())
    }

    pub async fn update_spdx_cache(&mut self) -> SpandxResult<()> {
        info!("Updating SPDX cache...");
        
        // Update only the SPDX repository
        if let Err(e) = self.git_operations.update_repository("spdx").await {
            warn!("Failed to update SPDX repository: {}", e);
            return Err(e.into());
        }
        
        info!("SPDX cache updated successfully");
        Ok(())
    }

    pub async fn update_rubygems_cache(&mut self) -> SpandxResult<()> {
        info!("Updating Ruby gems cache...");
        
        // Update only the RubyGems repository
        if let Err(e) = self.git_operations.update_repository("rubygems").await {
            warn!("Failed to update RubyGems repository: {}", e);
            return Err(e.into());
        }
        
        // Rebuild cache for RubyGems
        let cache_dir = self.git_operations
            .get_repository("rubygems")
            .ok_or_else(|| SpandxError::GitRepositoryNotFound {
                path: "rubygems".to_string()
            })?
            .cache_index_dir();
            
        if cache_dir.exists() {
            self.cache.rebuild_index("rubygems").await?;
            info!("RubyGems cache index rebuilt");
        }
        
        info!("Ruby gems cache updated successfully");
        Ok(())
    }

    pub async fn update_general_cache(&mut self) -> SpandxResult<()> {
        info!("Updating general cache...");
        
        // Update only the general cache repository
        if let Err(e) = self.git_operations.update_repository("cache").await {
            warn!("Failed to update cache repository: {}", e);
            return Err(e.into());
        }
        
        // Rebuild cache indices for all package managers
        if let Some(repo) = self.git_operations.get_repository("cache") {
            let cache_dir = repo.cache_index_dir();
            if cache_dir.exists() {
                // Rebuild for common package managers
                let package_managers = ["npm", "pypi", "nuget", "maven"];
                for pm in &package_managers {
                    if let Err(e) = self.cache.rebuild_index(pm).await {
                        warn!("Failed to rebuild index for {}: {}", pm, e);
                    } else {
                        info!("Rebuilt cache index for {}", pm);
                    }
                }
            }
        }
        
        info!("General cache updated successfully");
        Ok(())
    }
    
    /// Get status of all Git repositories
    pub async fn get_repository_status(&self) -> std::collections::HashMap<String, crate::git::operations::RepositoryStatusInfo> {
        self.git_operations.get_all_status().await
    }
    
    /// Get cache statistics
    pub async fn get_cache_stats(&mut self, package_manager: &str) -> SpandxResult<CacheStats> {
        self.cache.stats(package_manager).await
    }
    
    /// Read a file from a Git repository
    pub async fn read_git_file(&self, repo_name: &str, file_path: &str) -> SpandxResult<String> {
        self.git_operations.read_file(repo_name, file_path).await.map_err(|e| e.into())
    }
    
    /// Get memory cache (L1) statistics
    pub fn get_memory_cache_stats(&self) -> MemoryCacheStats {
        self.cache.memory_cache_stats()
    }
    
    /// Clear the L1 memory cache
    pub fn clear_memory_cache(&mut self) {
        self.cache.clear_memory_cache();
        info!("Cleared L1 memory cache");
    }
    
    /// Preload popular packages into L1 memory cache
    pub async fn preload_popular_packages(&mut self, package_manager: &str, limit: usize) -> SpandxResult<()> {
        info!("Preloading {} popular packages for {} into L1 cache", limit, package_manager);
        self.cache.preload_popular_packages(package_manager, limit).await?;
        
        let stats = self.cache.memory_cache_stats();
        info!("L1 cache now contains {} entries ({:.1}% utilization)", 
              stats.entries, stats.utilization() * 100.0);
        Ok(())
    }
    
    /// Get licenses for a package using hierarchical cache
    pub async fn get_licenses(&mut self, name: &str, version: &str, package_manager: &str) -> SpandxResult<Option<Vec<String>>> {
        self.cache.get_licenses(name, version, package_manager).await
    }
    
    /// Set licenses for a package in hierarchical cache
    pub async fn set_licenses(&mut self, name: &str, version: &str, package_manager: &str, licenses: Vec<String>) -> SpandxResult<()> {
        self.cache.set_licenses(name, version, package_manager, licenses).await
    }
    
    /// Optimize cache performance by warming up frequently accessed packages
    pub async fn optimize_cache_performance(&mut self) -> SpandxResult<()> {
        info!("Optimizing cache performance...");
        
        // Preload popular packages for major package managers
        let package_managers = [
            ("npm", 1000),
            ("pypi", 500), 
            ("rubygems", 300),
            ("maven", 200),
            ("nuget", 200),
        ];
        
        let mut total_preloaded = 0;
        for (pm, limit) in &package_managers {
            match self.preload_popular_packages(pm, *limit).await {
                Ok(_) => {
                    let stats = self.get_cache_stats(pm).await?;
                    total_preloaded += std::cmp::min(*limit, stats.total_entries);
                    info!("Preloaded up to {} packages for {}", limit, pm);
                }
                Err(e) => {
                    warn!("Failed to preload packages for {}: {}", pm, e);
                }
            }
        }
        
        let memory_stats = self.get_memory_cache_stats();
        info!("Cache optimization complete. Preloaded {} packages total. L1 cache: {}/{} entries ({:.1}% utilization)", 
              total_preloaded, memory_stats.entries, memory_stats.max_entries, memory_stats.utilization() * 100.0);
        
        Ok(())
    }
    
    /// Get comprehensive cache statistics for all levels
    pub async fn get_comprehensive_stats(&mut self) -> SpandxResult<ComprehensiveCacheStats> {
        let memory_stats = self.get_memory_cache_stats();
        
        // Get disk cache stats for major package managers
        let mut disk_stats = std::collections::HashMap::new();
        let package_managers = ["npm", "pypi", "rubygems", "maven", "nuget"];
        
        for pm in &package_managers {
            if let Ok(stats) = self.get_cache_stats(pm).await {
                disk_stats.insert(pm.to_string(), stats);
            }
        }
        
        Ok(ComprehensiveCacheStats {
            memory_cache: memory_stats,
            disk_cache: disk_stats,
        })
    }
}

#[derive(Debug, Clone)]
pub struct ComprehensiveCacheStats {
    pub memory_cache: MemoryCacheStats,
    pub disk_cache: std::collections::HashMap<String, CacheStats>,
}

impl ComprehensiveCacheStats {
    pub fn total_disk_entries(&self) -> usize {
        self.disk_cache.values().map(|stats| stats.total_entries).sum()
    }
    
    pub fn total_disk_buckets(&self) -> usize {
        self.disk_cache.values().map(|stats| stats.total_buckets).sum()
    }
    
    pub fn cache_efficiency_report(&self) -> String {
        let mut report = String::new();
        
        report.push_str(&format!("L1 Memory Cache: {}/{} entries ({:.1}% utilization)\n",
            self.memory_cache.entries, 
            self.memory_cache.max_entries,
            self.memory_cache.utilization() * 100.0));
        
        report.push_str(&format!("L2 Disk Cache: {} total entries across {} package managers\n",
            self.total_disk_entries(),
            self.disk_cache.len()));
        
        for (pm, stats) in &self.disk_cache {
            report.push_str(&format!("  {}: {} entries in {} buckets (avg {:.1} per bucket)\n",
                pm, 
                stats.total_entries, 
                stats.total_buckets,
                stats.avg_entries_per_bucket()));
        }
        
        report
    }
}