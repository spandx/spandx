use crate::cache::Cache;
use crate::git::GitRepository;
use anyhow::Result;
use std::collections::HashMap;
use tracing::{info, warn, debug};

/// High-level Git operations for cache management
pub struct GitOperations {
    repositories: HashMap<String, GitRepository>,
}

impl GitOperations {
    pub fn new(repositories: HashMap<String, GitRepository>) -> Self {
        Self { repositories }
    }
    
    /// Get a repository by name
    pub fn get_repository(&self, name: &str) -> Option<&GitRepository> {
        self.repositories.get(name)
    }
    
    /// Get a mutable repository by name
    pub fn get_repository_mut(&mut self, name: &str) -> Option<&mut GitRepository> {
        self.repositories.get_mut(name)
    }
    
    /// Update all repositories
    pub async fn update_all(&mut self) -> Result<UpdateResult> {
        info!("Updating all Git repositories");
        
        let mut successful = Vec::new();
        let mut failed = Vec::new();
        
        for (name, repo) in &mut self.repositories {
            match repo.update().await {
                Ok(_) => {
                    info!("Successfully updated repository: {}", name);
                    successful.push(name.clone());
                }
                Err(e) => {
                    warn!("Failed to update repository {}: {}", name, e);
                    failed.push((name.clone(), e));
                }
            }
        }
        
        Ok(UpdateResult {
            successful,
            failed,
        })
    }
    
    /// Update a specific repository
    pub async fn update_repository(&mut self, name: &str) -> Result<()> {
        if let Some(repo) = self.repositories.get_mut(name) {
            repo.update().await?;
            info!("Successfully updated repository: {}", name);
            Ok(())
        } else {
            Err(anyhow::anyhow!("Repository not found: {}", name))
        }
    }
    
    /// Build cache indices from all repositories
    pub async fn build_cache_indices(&self, cache: &mut Cache) -> Result<BuildResult> {
        info!("Building cache indices from Git repositories");
        
        let mut built_indices = Vec::new();
        let mut errors = Vec::new();
        
        // Process each repository that has cache data
        for (name, repo) in &self.repositories {
            if !repo.has_cache_data() {
                debug!("Repository {} has no cache data, skipping", name);
                continue;
            }
            
            match self.build_cache_for_repository(cache, repo).await {
                Ok(count) => {
                    info!("Built cache index for {} with {} entries", name, count);
                    built_indices.push((name.clone(), count));
                }
                Err(e) => {
                    warn!("Failed to build cache for repository {}: {}", name, e);
                    errors.push((name.clone(), e));
                }
            }
        }
        
        Ok(BuildResult {
            built_indices,
            errors,
        })
    }
    
    /// Build cache for a specific repository
    async fn build_cache_for_repository(&self, cache: &mut Cache, repo: &GitRepository) -> Result<usize> {
        let cache_dir = repo.cache_index_dir();
        
        if !cache_dir.exists() {
            return Ok(0);
        }
        
        let mut total_entries = 0;
        
        // List all package manager directories
        let mut entries = tokio::fs::read_dir(&cache_dir).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.is_dir() {
                if let Some(package_manager) = path.file_name().and_then(|n| n.to_str()) {
                    // Skip hidden directories
                    if package_manager.starts_with('.') {
                        continue;
                    }
                    
                    debug!("Building cache for package manager: {}", package_manager);
                    match self.import_package_manager_data(cache, &cache_dir, package_manager).await {
                        Ok(count) => {
                            total_entries += count;
                            debug!("Imported {} entries for {}", count, package_manager);
                        }
                        Err(e) => {
                            warn!("Failed to import data for {}: {}", package_manager, e);
                        }
                    }
                }
            }
        }
        
        Ok(total_entries)
    }
    
    /// Import data for a specific package manager
    async fn import_package_manager_data(&self, cache: &mut Cache, cache_dir: &camino::Utf8Path, package_manager: &str) -> Result<usize> {
        let pm_dir = cache_dir.join(package_manager);
        let mut total_entries = 0;
        
        // Process all bucket directories (00-ff)
        let mut entries = tokio::fs::read_dir(&pm_dir).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.is_dir() {
                if let Some(bucket) = path.file_name().and_then(|n| n.to_str()) {
                    // Validate bucket name (should be 2-digit hex)
                    if bucket.len() == 2 && bucket.chars().all(|c| c.is_ascii_hexdigit()) {
                        match self.import_bucket_data(cache, &pm_dir, bucket, package_manager).await {
                            Ok(count) => {
                                total_entries += count;
                            }
                            Err(e) => {
                                debug!("Failed to import bucket {} for {}: {}", bucket, package_manager, e);
                            }
                        }
                    }
                }
            }
        }
        
        Ok(total_entries)
    }
    
    /// Import data for a specific bucket
    async fn import_bucket_data(&self, cache: &mut Cache, pm_dir: &camino::Utf8Path, bucket: &str, package_manager: &str) -> Result<usize> {
        let bucket_dir = pm_dir.join(bucket);
        let data_file = bucket_dir.join(package_manager);
        
        if !data_file.exists() {
            return Ok(0);
        }
        
        // Read the CSV data file
        let content = tokio::fs::read_to_string(&data_file).await?;
        let mut entry_count = 0;
        
        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }
            
            // Parse CSV line: "name","version","license1-|-license2"
            match self.parse_cache_line(line) {
                Ok((name, version, licenses)) => {
                    cache.set_licenses(&name, &version, package_manager, licenses).await?;
                    entry_count += 1;
                }
                Err(e) => {
                    debug!("Failed to parse cache line: {} - {}", line, e);
                }
            }
        }
        
        Ok(entry_count)
    }
    
    /// Parse a cache line from CSV format
    fn parse_cache_line(&self, line: &str) -> Result<(String, String, Vec<String>)> {
        let mut reader = csv::ReaderBuilder::new()
            .has_headers(false)
            .from_reader(line.as_bytes());
        
        if let Some(result) = reader.records().next() {
            let record = result?;
            if record.len() >= 3 {
                let name = record[0].to_string();
                let version = record[1].to_string();
                let licenses_str = &record[2];
                
                let licenses = if licenses_str.is_empty() {
                    Vec::new()
                } else {
                    licenses_str.split("-|-").map(|s| s.to_string()).collect()
                };
                
                return Ok((name, version, licenses));
            }
        }
        
        Err(anyhow::anyhow!("Invalid CSV line: {}", line))
    }
    
    /// Get status of all repositories
    pub async fn get_all_status(&self) -> HashMap<String, RepositoryStatusInfo> {
        let mut statuses = HashMap::new();
        
        for (name, repo) in &self.repositories {
            let status = match repo.status().await {
                Ok(status) => status,
                Err(e) => {
                    warn!("Failed to get status for repository {}: {}", name, e);
                    continue;
                }
            };
            
            let last_commit = repo.last_commit_hash().await.unwrap_or_else(|_| "unknown".to_string());
            let has_cache = repo.has_cache_data();
            
            statuses.insert(name.clone(), RepositoryStatusInfo {
                status,
                last_commit,
                has_cache_data: has_cache,
                local_path: repo.local_path().to_path_buf(),
            });
        }
        
        statuses
    }
    
    /// Read a file from a specific repository
    pub async fn read_file(&self, repo_name: &str, file_path: &str) -> Result<String> {
        if let Some(repo) = self.repositories.get(repo_name) {
            repo.read_file(file_path).await
        } else {
            Err(anyhow::anyhow!("Repository not found: {}", repo_name))
        }
    }
}

#[derive(Debug)]
pub struct UpdateResult {
    pub successful: Vec<String>,
    pub failed: Vec<(String, anyhow::Error)>,
}

impl UpdateResult {
    pub fn is_success(&self) -> bool {
        self.failed.is_empty()
    }
    
    pub fn partial_success(&self) -> bool {
        !self.successful.is_empty() && !self.failed.is_empty()
    }
}

#[derive(Debug)]
pub struct BuildResult {
    pub built_indices: Vec<(String, usize)>,
    pub errors: Vec<(String, anyhow::Error)>,
}

impl BuildResult {
    pub fn total_entries(&self) -> usize {
        self.built_indices.iter().map(|(_, count)| count).sum()
    }
    
    pub fn is_success(&self) -> bool {
        self.errors.is_empty()
    }
}

#[derive(Debug, Clone)]
pub struct RepositoryStatusInfo {
    pub status: crate::git::repository::RepositoryStatus,
    pub last_commit: String,
    pub has_cache_data: bool,
    pub local_path: camino::Utf8PathBuf,
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    use camino::Utf8PathBuf;
    
    #[test]
    fn test_parse_cache_line() {
        let ops = GitOperations::new(HashMap::new());
        
        // Test normal case
        let result = ops.parse_cache_line("\"rails\",\"7.0.0\",\"MIT-|-Apache-2.0\"").unwrap();
        assert_eq!(result.0, "rails");
        assert_eq!(result.1, "7.0.0");
        assert_eq!(result.2, vec!["MIT", "Apache-2.0"]);
        
        // Test empty licenses
        let result = ops.parse_cache_line("\"unknown\",\"1.0.0\",\"\"").unwrap();
        assert_eq!(result.0, "unknown");
        assert_eq!(result.1, "1.0.0");
        assert!(result.2.is_empty());
        
        // Test single license
        let result = ops.parse_cache_line("\"sinatra\",\"2.0.0\",\"MIT\"").unwrap();
        assert_eq!(result.0, "sinatra");
        assert_eq!(result.1, "2.0.0");
        assert_eq!(result.2, vec!["MIT"]);
    }
    
    #[tokio::test]
    async fn test_git_operations_creation() {
        let temp_dir = TempDir::new().unwrap();
        let path = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        
        let mut repos = HashMap::new();
        repos.insert(
            "test".to_string(),
            GitRepository::new(
                "https://github.com/example/repo.git".to_string(),
                "main".to_string(),
                path.join("test-repo"),
            ),
        );
        
        let ops = GitOperations::new(repos);
        assert!(ops.get_repository("test").is_some());
        assert!(ops.get_repository("nonexistent").is_none());
    }
}