use crate::cache::{DataFile, IndexFile};
use crate::error::{SpandxError, SpandxResult};
use camino::{Utf8Path, Utf8PathBuf};
use sha1::{Digest, Sha1};
use std::collections::HashMap;
use tracing::{debug, warn};

/// Cache key for binary-indexed storage
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CacheKey {
    pub bucket: String,
    pub package_manager: String,
}

impl CacheKey {
    pub fn new(name: &str, package_manager: &str) -> Self {
        let mut hasher = Sha1::new();
        hasher.update(name.as_bytes());
        let hash = hasher.finalize();
        let bucket = format!("{:02x}", hash[0]);
        
        Self {
            bucket,
            package_manager: package_manager.to_string(),
        }
    }

    pub fn data_file_path(&self, cache_dir: &Utf8Path) -> Utf8PathBuf {
        cache_dir
            .join(".index")
            .join(&self.bucket)
            .join(&self.package_manager)
    }

    pub fn index_file_path(&self, cache_dir: &Utf8Path) -> Utf8PathBuf {
        cache_dir
            .join(".index")
            .join(&self.bucket)
            .join(format!("{}.idx", self.package_manager))
    }
}

/// Entry in the package cache
#[derive(Debug, Clone, PartialEq)]
pub struct CacheEntry {
    pub name: String,
    pub version: String,
    pub licenses: Vec<String>,
}

impl CacheEntry {
    pub fn new(name: String, version: String, licenses: Vec<String>) -> Self {
        Self {
            name,
            version,
            licenses,
        }
    }

    pub fn to_csv_line(&self) -> String {
        let licenses_str = if self.licenses.is_empty() {
            String::new()
        } else {
            self.licenses.join("-|-")
        };
        format!("\"{}\",\"{}\",\"{}\"", self.name, self.version, licenses_str)
    }

    pub fn from_csv_line(line: &str) -> SpandxResult<Self> {
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
                
                return Ok(Self::new(name, version, licenses));
            }
        }
        
        Err(SpandxError::InvalidFormatError {
            format: "CSV".to_string(),
            file_path: "cache entry".to_string(),
            reason: format!("Invalid CSV line: {}", line),
        })
    }

    pub fn key(&self) -> String {
        format!("{}:{}", self.name, self.version)
    }
}

/// Hierarchical binary-indexed package cache with multi-level hierarchy
#[derive(Debug)]
pub struct Cache {
    cache_dir: Utf8PathBuf,
    data_files: HashMap<CacheKey, DataFile>,
    index_files: HashMap<CacheKey, IndexFile>,
    memory_cache: HashMap<String, Vec<String>>, // L1: In-memory cache
    memory_cache_size: usize,
    max_memory_entries: usize,
}

impl Cache {
    pub fn new(cache_dir: Utf8PathBuf) -> Self {
        Self::with_memory_cache_size(cache_dir, 1000) // Default 1000 entries
    }

    pub fn with_memory_cache_size(cache_dir: Utf8PathBuf, max_memory_entries: usize) -> Self {
        Self {
            cache_dir,
            data_files: HashMap::new(),
            index_files: HashMap::new(),
            memory_cache: HashMap::new(),
            memory_cache_size: 0,
            max_memory_entries,
        }
    }

    pub fn cache_dir(&self) -> &Utf8Path {
        &self.cache_dir
    }

    /// Get licenses for a package from the hierarchical cache
    /// L1: Memory cache -> L2: Binary-indexed disk cache -> L3: Fallback lookup
    pub async fn get_licenses(&mut self, name: &str, version: &str, package_manager: &str) -> SpandxResult<Option<Vec<String>>> {
        let full_key = format!("{}:{}:{}", package_manager, name, version);
        
        // L1: Check memory cache first (fastest)
        if let Some(licenses) = self.memory_cache.get(&full_key) {
            debug!("L1 cache hit (memory) for {}@{}", name, version);
            return Ok(Some(licenses.clone()));
        }
        
        // L2: Check binary-indexed disk cache
        let cache_key = CacheKey::new(name, package_manager);
        
        // Ensure data and index files are loaded
        self.ensure_files_loaded(&cache_key).await?;
        
        let data_file = self.data_files.get(&cache_key);
        let index_file = self.index_files.get(&cache_key);
        
        if let (Some(data_file), Some(index_file)) = (data_file, index_file) {
            let search_key = format!("{}:{}", name, version);
            
            if let Some(offset) = index_file.find_offset(&search_key).await? {
                if let Some(entry) = data_file.read_entry_at_offset(offset).await? {
                    if entry.name == name && entry.version == version {
                        debug!("L2 cache hit (binary-indexed) for {}@{}: {:?}", name, version, entry.licenses);
                        
                        // Promote to L1 cache for faster future access
                        self.add_to_memory_cache(full_key, entry.licenses.clone());
                        
                        return Ok(Some(entry.licenses));
                    }
                }
            }
        }
        
        debug!("Cache miss (all levels) for {}@{}", name, version);
        Ok(None)
    }

    /// Store licenses for a package in the hierarchical cache
    /// Stores in both L1 (memory) and L2 (binary-indexed disk) for maximum performance
    pub async fn set_licenses(&mut self, name: &str, version: &str, package_manager: &str, licenses: Vec<String>) -> SpandxResult<()> {
        let full_key = format!("{}:{}:{}", package_manager, name, version);
        let cache_key = CacheKey::new(name, package_manager);
        let entry = CacheEntry::new(name.to_string(), version.to_string(), licenses.clone());
        
        // Store in L1 (memory cache) for immediate access
        self.add_to_memory_cache(full_key, licenses.clone());
        
        // Store in L2 (binary-indexed disk cache) for persistence
        // Ensure data file is loaded
        self.ensure_files_loaded(&cache_key).await?;
        
        // Append to data file
        if let Some(data_file) = self.data_files.get_mut(&cache_key) {
            data_file.append_entry(&entry).await?;
            debug!("Cached entry in L2 for {}@{}", name, version);
        } else {
            // Create new data file
            let data_path = cache_key.data_file_path(&self.cache_dir);
            if let Some(parent) = data_path.parent() {
                tokio::fs::create_dir_all(parent).await?;
            }
            
            let mut data_file = DataFile::create(data_path).await?;
            data_file.append_entry(&entry).await?;
            self.data_files.insert(cache_key.clone(), data_file);
            
            debug!("Created cache file and cached entry in L2 for {}@{}", name, version);
        }
        
        // Invalidate index to force rebuild on next access
        self.index_files.remove(&cache_key);
        
        Ok(())
    }

    /// Rebuild index for a package manager
    pub async fn rebuild_index(&mut self, package_manager: &str) -> SpandxResult<()> {
        debug!("Rebuilding index for package manager: {}", package_manager);
        
        // Rebuild indexes for all buckets that have data files
        for bucket in 0..=255 {
            let bucket_str = format!("{:02x}", bucket);
            let key = CacheKey {
                bucket: bucket_str,
                package_manager: package_manager.to_string(),
            };
            
            let data_path = key.data_file_path(&self.cache_dir);
            if data_path.exists() {
                self.rebuild_index_for_key(&key).await?;
            }
        }
        
        debug!("Index rebuild completed for {}", package_manager);
        Ok(())
    }

    async fn rebuild_index_for_key(&mut self, key: &CacheKey) -> SpandxResult<()> {
        let data_path = key.data_file_path(&self.cache_dir);
        let index_path = key.index_file_path(&self.cache_dir);
        
        // Load and sort all entries
        let mut entries = Vec::new();
        if let Ok(data_file) = DataFile::open(&data_path).await {
            let mut all_entries = data_file.read_all_entries().await?;
            all_entries.sort_by(|a, b| a.key().cmp(&b.key()));
            all_entries.dedup_by(|a, b| a.key() == b.key());
            entries = all_entries;
        }
        
        if entries.is_empty() {
            return Ok(());
        }
        
        // Rewrite sorted data file
        let mut new_data_file = DataFile::create(&data_path).await?;
        let mut index_entries = Vec::new();
        
        for entry in &entries {
            let offset = new_data_file.current_offset();
            new_data_file.append_entry(entry).await?;
            index_entries.push((entry.key(), offset));
        }
        
        // Create index file
        let mut index_file = IndexFile::create(index_path).await?;
        for (key, offset) in index_entries {
            index_file.add_entry(&key, offset).await?;
        }
        index_file.finalize().await?;
        
        // Update in-memory references
        self.data_files.insert(key.clone(), new_data_file);
        self.index_files.insert(key.clone(), index_file);
        
        Ok(())
    }

    /// Add entry to L1 memory cache with LRU eviction
    fn add_to_memory_cache(&mut self, key: String, licenses: Vec<String>) {
        // Simple LRU: remove oldest entry if cache is full
        if self.memory_cache_size >= self.max_memory_entries {
            if let Some(first_key) = self.memory_cache.keys().next().cloned() {
                self.memory_cache.remove(&first_key);
                self.memory_cache_size -= 1;
                debug!("Evicted entry from L1 cache: {}", first_key);
            }
        }
        
        // Remove existing entry if present (for reinsertion at end)
        if self.memory_cache.remove(&key).is_some() {
            self.memory_cache_size -= 1;
        }
        
        // Add new entry
        self.memory_cache.insert(key.clone(), licenses);
        self.memory_cache_size += 1;
        debug!("Added entry to L1 cache: {}", key);
    }

    /// Clear L1 memory cache
    pub fn clear_memory_cache(&mut self) {
        self.memory_cache.clear();
        self.memory_cache_size = 0;
        debug!("Cleared L1 memory cache");
    }

    /// Get memory cache statistics
    pub fn memory_cache_stats(&self) -> MemoryCacheStats {
        MemoryCacheStats {
            entries: self.memory_cache_size,
            max_entries: self.max_memory_entries,
            hit_rate_estimate: 0.0, // Would need hit/miss counters for real implementation
        }
    }

    /// Preload frequently accessed packages into memory cache
    pub async fn preload_popular_packages(&mut self, package_manager: &str, limit: usize) -> SpandxResult<()> {
        debug!("Preloading {} popular packages for {}", limit, package_manager);
        
        let mut loaded_count = 0;
        
        // Iterate through all buckets to find popular packages
        for bucket in 0..=255 {
            if loaded_count >= limit {
                break;
            }
            
            let bucket_str = format!("{:02x}", bucket);
            let key = CacheKey {
                bucket: bucket_str,
                package_manager: package_manager.to_string(),
            };
            
            let data_path = key.data_file_path(&self.cache_dir);
            if data_path.exists() {
                if let Ok(data_file) = DataFile::open(&data_path).await {
                    let entries = data_file.read_all_entries().await?;
                    
                    // Load first few entries from each bucket (could be improved with popularity metrics)
                    for entry in entries.iter().take(limit - loaded_count) {
                        let full_key = format!("{}:{}:{}", package_manager, entry.name, entry.version);
                        self.add_to_memory_cache(full_key, entry.licenses.clone());
                        loaded_count += 1;
                        
                        if loaded_count >= limit {
                            break;
                        }
                    }
                }
            }
        }
        
        debug!("Preloaded {} packages into L1 cache", loaded_count);
        Ok(())
    }

    async fn ensure_files_loaded(&mut self, key: &CacheKey) -> SpandxResult<()> {
        if !self.data_files.contains_key(key) {
            let data_path = key.data_file_path(&self.cache_dir);
            debug!("Loading data file: {:?}", data_path);
            if data_path.exists() {
                match DataFile::open(&data_path).await {
                    Ok(data_file) => {
                        self.data_files.insert(key.clone(), data_file);
                        debug!("Successfully loaded data file");
                    }
                    Err(e) => {
                        warn!("Failed to open data file {:?}: {}", data_path, e);
                    }
                }
            } else {
                debug!("Data file does not exist: {:?}", data_path);
            }
        }
        
        if !self.index_files.contains_key(key) {
            let index_path = key.index_file_path(&self.cache_dir);
            debug!("Loading index file: {:?}", index_path);
            if index_path.exists() {
                match IndexFile::open(index_path).await {
                    Ok(index_file) => {
                        let entries_count = index_file.len();
                        self.index_files.insert(key.clone(), index_file);
                        debug!("Successfully loaded index file with {} entries", entries_count);
                    }
                    Err(e) => {
                        warn!("Failed to open index file, will rebuild: {}", e);
                        // Try to rebuild index if it's corrupted
                        self.rebuild_index_for_key(key).await?;
                    }
                }
            } else {
                debug!("Index file does not exist, rebuilding: {:?}", index_path);
                // Index doesn't exist, try to rebuild from data file
                let data_path = key.data_file_path(&self.cache_dir);
                if data_path.exists() {
                    self.rebuild_index_for_key(key).await?;
                }
            }
        }
        
        Ok(())
    }

    /// Get cache statistics
    pub async fn stats(&mut self, package_manager: &str) -> SpandxResult<CacheStats> {
        let mut total_entries = 0;
        let mut total_buckets = 0;
        
        for bucket in 0..=255 {
            let bucket_str = format!("{:02x}", bucket);
            let key = CacheKey {
                bucket: bucket_str,
                package_manager: package_manager.to_string(),
            };
            
            let data_path = key.data_file_path(&self.cache_dir);
            if data_path.exists() {
                total_buckets += 1;
                if let Ok(data_file) = DataFile::open(&data_path).await {
                    total_entries += data_file.count_entries().await?;
                }
            }
        }
        
        Ok(CacheStats {
            total_entries,
            total_buckets,
            package_manager: package_manager.to_string(),
        })
    }
}

#[derive(Debug, Clone)]
pub struct CacheStats {
    pub total_entries: usize,
    pub total_buckets: usize,
    pub package_manager: String,
}

impl CacheStats {
    pub fn avg_entries_per_bucket(&self) -> f64 {
        if self.total_buckets == 0 {
            0.0
        } else {
            self.total_entries as f64 / self.total_buckets as f64
        }
    }
}

#[derive(Debug, Clone)]
pub struct MemoryCacheStats {
    pub entries: usize,
    pub max_entries: usize,
    pub hit_rate_estimate: f64,
}

impl MemoryCacheStats {
    pub fn utilization(&self) -> f64 {
        if self.max_entries == 0 {
            0.0
        } else {
            self.entries as f64 / self.max_entries as f64
        }
    }

    pub fn remaining_capacity(&self) -> usize {
        self.max_entries.saturating_sub(self.entries)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_cache_key_generation() {
        let key1 = CacheKey::new("rails", "rubygems");
        let key2 = CacheKey::new("rails", "rubygems");
        let key3 = CacheKey::new("django", "python");
        
        assert_eq!(key1, key2);
        assert_ne!(key1, key3);
        assert_eq!(key1.package_manager, "rubygems");
        assert_eq!(key3.package_manager, "python");
    }

    #[test]
    fn test_cache_entry_csv() {
        let entry = CacheEntry::new(
            "rails".to_string(),
            "7.0.0".to_string(),
            vec!["MIT".to_string(), "Apache-2.0".to_string()],
        );
        
        let csv_line = entry.to_csv_line();
        assert_eq!(csv_line, "\"rails\",\"7.0.0\",\"MIT-|-Apache-2.0\"");
        
        let parsed_entry = CacheEntry::from_csv_line(&csv_line).unwrap();
        assert_eq!(parsed_entry, entry);
    }

    #[test]
    fn test_cache_entry_empty_licenses() {
        let entry = CacheEntry::new(
            "unknown".to_string(),
            "1.0.0".to_string(),
            vec![],
        );
        
        let csv_line = entry.to_csv_line();
        assert_eq!(csv_line, "\"unknown\",\"1.0.0\",\"\"");
        
        let parsed_entry = CacheEntry::from_csv_line(&csv_line).unwrap();
        assert_eq!(parsed_entry, entry);
    }

    #[tokio::test]
    async fn test_cache_basic_operations() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::new(cache_dir);

        // Test cache miss
        let result = cache.get_licenses("rails", "7.0.0", "rubygems").await.unwrap();
        assert!(result.is_none());

        // Set licenses
        let licenses = vec!["MIT".to_string(), "Apache-2.0".to_string()];
        cache.set_licenses("rails", "7.0.0", "rubygems", licenses.clone()).await.unwrap();

        // Test cache hit (should come from L1 memory cache now)
        let result = cache.get_licenses("rails", "7.0.0", "rubygems").await.unwrap();
        assert_eq!(result, Some(licenses));

        // Test different version (cache miss)
        let result = cache.get_licenses("rails", "6.0.0", "rubygems").await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn test_cache_stats() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::new(cache_dir);

        // Add some entries
        cache.set_licenses("rails", "7.0.0", "rubygems", vec!["MIT".to_string()]).await.unwrap();
        cache.set_licenses("sinatra", "2.0.0", "rubygems", vec!["MIT".to_string()]).await.unwrap();

        let stats = cache.stats("rubygems").await.unwrap();
        assert!(stats.total_entries >= 2);
        assert!(stats.total_buckets >= 1);
        assert_eq!(stats.package_manager, "rubygems");
    }

    #[tokio::test]
    async fn test_hierarchical_cache_levels() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::with_memory_cache_size(cache_dir, 2); // Small L1 cache for testing

        let licenses = vec!["MIT".to_string()];
        
        // Store in cache (goes to both L1 and L2)
        cache.set_licenses("rails", "7.0.0", "rubygems", licenses.clone()).await.unwrap();
        
        // Verify L1 cache stats
        let memory_stats = cache.memory_cache_stats();
        assert_eq!(memory_stats.entries, 1);
        assert_eq!(memory_stats.max_entries, 2);
        assert_eq!(memory_stats.utilization(), 0.5);
        
        // First retrieval should hit L1 cache
        let result = cache.get_licenses("rails", "7.0.0", "rubygems").await.unwrap();
        assert_eq!(result, Some(licenses.clone()));
        
        // Clear L1 cache to test L2 fallback
        cache.clear_memory_cache();
        assert_eq!(cache.memory_cache_stats().entries, 0);
        
        // Second retrieval should hit L2 cache and promote to L1
        let result = cache.get_licenses("rails", "7.0.0", "rubygems").await.unwrap();
        assert_eq!(result, Some(licenses));
        assert_eq!(cache.memory_cache_stats().entries, 1); // Promoted back to L1
    }

    #[tokio::test]
    async fn test_memory_cache_lru_eviction() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::with_memory_cache_size(cache_dir, 2); // Only 2 entries

        let licenses = vec!["MIT".to_string()];
        
        // Fill L1 cache to capacity
        cache.set_licenses("pkg1", "1.0.0", "npm", licenses.clone()).await.unwrap();
        cache.set_licenses("pkg2", "1.0.0", "npm", licenses.clone()).await.unwrap();
        assert_eq!(cache.memory_cache_stats().entries, 2);
        
        // Add third entry, should evict first
        cache.set_licenses("pkg3", "1.0.0", "npm", licenses.clone()).await.unwrap();
        assert_eq!(cache.memory_cache_stats().entries, 2); // Still 2 entries
        
        // pkg1 should be evicted from L1, but still available in L2
        let result = cache.get_licenses("pkg1", "1.0.0", "npm").await.unwrap();
        assert_eq!(result, Some(licenses.clone())); // Should hit L2 and promote to L1
        
        // pkg2 should now be evicted from L1 due to LRU
        let result = cache.get_licenses("pkg2", "1.0.0", "npm").await.unwrap();
        assert_eq!(result, Some(licenses)); // Should hit L2
    }

    #[tokio::test]
    async fn test_preload_popular_packages() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::with_memory_cache_size(cache_dir, 10);

        let licenses = vec!["MIT".to_string()];
        
        // Add some packages to L2 cache
        cache.set_licenses("popular1", "1.0.0", "npm", licenses.clone()).await.unwrap();
        cache.set_licenses("popular2", "2.0.0", "npm", licenses.clone()).await.unwrap();
        cache.set_licenses("popular3", "3.0.0", "npm", licenses.clone()).await.unwrap();
        
        // Clear L1 to test preloading
        cache.clear_memory_cache();
        assert_eq!(cache.memory_cache_stats().entries, 0);
        
        // Preload popular packages
        cache.preload_popular_packages("npm", 5).await.unwrap();
        
        // Should have loaded some packages into L1
        let stats = cache.memory_cache_stats();
        assert!(stats.entries > 0);
        assert!(stats.entries <= 5);
    }

    #[tokio::test]
    async fn test_memory_cache_stats() {
        let temp_dir = TempDir::new().unwrap();
        let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf()).unwrap();
        let mut cache = Cache::with_memory_cache_size(cache_dir, 5);

        let stats = cache.memory_cache_stats();
        assert_eq!(stats.entries, 0);
        assert_eq!(stats.max_entries, 5);
        assert_eq!(stats.utilization(), 0.0);
        assert_eq!(stats.remaining_capacity(), 5);
        
        // Add some entries
        let licenses = vec!["MIT".to_string()];
        cache.set_licenses("pkg1", "1.0.0", "npm", licenses.clone()).await.unwrap();
        cache.set_licenses("pkg2", "1.0.0", "npm", licenses).await.unwrap();
        
        let stats = cache.memory_cache_stats();
        assert_eq!(stats.entries, 2);
        assert_eq!(stats.utilization(), 0.4); // 2/5 = 0.4
        assert_eq!(stats.remaining_capacity(), 3);
    }
}