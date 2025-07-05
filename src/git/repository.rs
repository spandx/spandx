use anyhow::Result;
use camino::{Utf8Path, Utf8PathBuf};
use git2::{BranchType, Repository, RemoteCallbacks, FetchOptions};
use std::path::Path;
use tracing::{debug, info};

/// Represents a Git repository for cache management
#[derive(Debug, Clone)]
pub struct GitRepository {
    url: String,
    branch: String,
    local_path: Utf8PathBuf,
    name: String,
}

impl GitRepository {
    pub fn new(url: String, branch: String, local_path: Utf8PathBuf) -> Self {
        let name = local_path
            .file_name()
            .unwrap_or("unknown")
            .to_string();
        
        Self {
            url,
            branch,
            local_path,
            name,
        }
    }
    
    pub fn name(&self) -> &str {
        &self.name
    }
    
    pub fn url(&self) -> &str {
        &self.url
    }
    
    pub fn branch(&self) -> &str {
        &self.branch
    }
    
    pub fn local_path(&self) -> &Utf8Path {
        &self.local_path
    }
    
    /// Check if the repository exists locally
    pub fn exists(&self) -> bool {
        self.local_path.join(".git").exists()
    }
    
    /// Update the repository (clone if not exists, pull if exists)
    pub async fn update(&mut self) -> Result<()> {
        if self.exists() {
            self.pull().await
        } else {
            self.clone().await
        }
    }
    
    /// Clone the repository
    pub async fn clone(&self) -> Result<()> {
        info!("Cloning repository {} to {:?}", self.url, self.local_path);
        
        // Ensure parent directory exists
        if let Some(parent) = self.local_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        // Perform clone operation in blocking thread
        let url = self.url.clone();
        let branch = self.branch.clone();
        let local_path = self.local_path.clone();
        
        tokio::task::spawn_blocking(move || -> Result<()> {
            let mut builder = git2::build::RepoBuilder::new();
            
            // Configure for shallow clone
            let mut fetch_opts = FetchOptions::new();
            fetch_opts.depth(1);
            
            // Set up progress callback
            let mut callbacks = RemoteCallbacks::new();
            callbacks.pack_progress(|_stage, current, total| {
                if current > 0 {
                    debug!(
                        "Clone progress: {}/{}",
                        current,
                        total
                    );
                }
            });
            
            fetch_opts.remote_callbacks(callbacks);
            builder.fetch_options(fetch_opts);
            
            // Set branch
            builder.branch(&branch);
            
            // Perform clone
            let repo = builder.clone(&url, Path::new(&local_path))?;
            
            debug!("Successfully cloned repository to {:?}", local_path);
            
            // Verify checkout
            let head = repo.head()?;
            if let Some(name) = head.shorthand() {
                debug!("Checked out branch: {}", name);
            }
            
            Ok(())
        }).await??;
        
        info!("Clone completed for {}", self.name);
        Ok(())
    }
    
    /// Pull latest changes
    pub async fn pull(&self) -> Result<()> {
        info!("Pulling latest changes for repository {}", self.name);
        
        let local_path = self.local_path.clone();
        let branch = self.branch.clone();
        
        tokio::task::spawn_blocking(move || -> Result<()> {
            let repo = Repository::open(Path::new(&local_path))?;
            
            // Fetch from origin
            let mut remote = repo.find_remote("origin")?;
            
            let mut fetch_opts = FetchOptions::new();
            fetch_opts.depth(1);
            
            // Set up progress callback
            let mut callbacks = RemoteCallbacks::new();
            callbacks.pack_progress(|_stage, current, total| {
                if current > 0 {
                    debug!(
                        "Fetch progress: {}/{}",
                        current,
                        total
                    );
                }
            });
            
            fetch_opts.remote_callbacks(callbacks);
            
            // Fetch the branch
            let refspec = format!("refs/heads/{}:refs/remotes/origin/{}", branch, branch);
            remote.fetch(&[&refspec], Some(&mut fetch_opts), None)?;
            
            debug!("Fetch completed");
            
            // Find the target branch
            let remote_branch_name = format!("origin/{}", branch);
            let remote_branch = repo.find_branch(&remote_branch_name, BranchType::Remote)?;
            let remote_commit = remote_branch.get().peel_to_commit()?;
            
            // Checkout the commit
            let tree = remote_commit.tree()?;
            repo.checkout_tree(tree.as_object(), None)?;
            
            // Update HEAD to point to the new commit
            repo.set_head_detached(remote_commit.id())?;
            
            debug!("Checked out latest commit: {}", remote_commit.id());
            
            Ok(())
        }).await??;
        
        info!("Pull completed for {}", self.name);
        Ok(())
    }
    
    /// Read a file from the repository
    pub async fn read_file<P: AsRef<Utf8Path>>(&self, path: P) -> Result<String> {
        let file_path = self.local_path.join(path.as_ref());
        
        if !file_path.exists() {
            return Err(anyhow::anyhow!(
                "File does not exist: {:?}",
                file_path
            ));
        }
        
        let content = tokio::fs::read_to_string(&file_path).await?;
        Ok(content)
    }
    
    /// List files in a directory within the repository
    pub async fn list_files<P: AsRef<Utf8Path>>(&self, dir_path: P) -> Result<Vec<Utf8PathBuf>> {
        let full_path = self.local_path.join(dir_path.as_ref());
        
        if !full_path.exists() {
            return Ok(Vec::new());
        }
        
        let mut files = Vec::new();
        let mut entries = tokio::fs::read_dir(&full_path).await?;
        
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.is_file() {
                if let Ok(utf8_path) = Utf8PathBuf::from_path_buf(path) {
                    // Make path relative to repository root
                    if let Ok(relative_path) = utf8_path.strip_prefix(&self.local_path) {
                        files.push(relative_path.to_path_buf());
                    }
                }
            }
        }
        
        Ok(files)
    }
    
    /// Get the cache index directory for this repository
    pub fn cache_index_dir(&self) -> Utf8PathBuf {
        self.local_path.join(".index")
    }
    
    /// Check if the repository has cache data
    pub fn has_cache_data(&self) -> bool {
        self.cache_index_dir().exists()
    }
    
    /// Get the last commit hash
    pub async fn last_commit_hash(&self) -> Result<String> {
        let local_path = self.local_path.clone();
        
        tokio::task::spawn_blocking(move || -> Result<String> {
            let repo = Repository::open(Path::new(&local_path))?;
            let head = repo.head()?;
            let commit = head.peel_to_commit()?;
            Ok(commit.id().to_string())
        }).await?
    }
    
    /// Get repository status
    pub async fn status(&self) -> Result<RepositoryStatus> {
        if !self.exists() {
            return Ok(RepositoryStatus::NotCloned);
        }
        
        let local_path = self.local_path.clone();
        
        tokio::task::spawn_blocking(move || -> Result<RepositoryStatus> {
            let repo = Repository::open(Path::new(&local_path))?;
            
            // Check if there are any uncommitted changes
            let statuses = repo.statuses(None)?;
            if !statuses.is_empty() {
                return Ok(RepositoryStatus::Dirty);
            }
            
            // Check if we're ahead/behind remote
            let head = repo.head()?;
            let local_commit = head.peel_to_commit()?;
            
            Ok(RepositoryStatus::Clean {
                commit_hash: local_commit.id().to_string(),
                commit_message: local_commit.message().unwrap_or("").to_string(),
            })
        }).await?
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum RepositoryStatus {
    NotCloned,
    Dirty,
    Clean {
        commit_hash: String,
        commit_message: String,
    },
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_repository_creation() {
        let temp_dir = TempDir::new().unwrap();
        let path = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        
        let repo = GitRepository::new(
            "https://github.com/example/repo.git".to_string(),
            "main".to_string(),
            path.join("test-repo"),
        );
        
        assert_eq!(repo.url(), "https://github.com/example/repo.git");
        assert_eq!(repo.branch(), "main");
        assert_eq!(repo.name(), "test-repo");
        assert!(!repo.exists());
    }
    
    #[test]
    fn test_cache_paths() {
        let temp_dir = TempDir::new().unwrap();
        let path = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        
        let repo = GitRepository::new(
            "https://github.com/example/repo.git".to_string(),
            "main".to_string(),
            path.join("test-repo"),
        );
        
        let cache_dir = repo.cache_index_dir();
        assert_eq!(cache_dir, path.join("test-repo").join(".index"));
        assert!(!repo.has_cache_data());
    }
}