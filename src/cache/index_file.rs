use crate::error::SpandxResult;
use camino::{Utf8Path, Utf8PathBuf};
use std::collections::BTreeMap;
use tokio::fs::{File, OpenOptions};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tracing::debug;

/// Binary index file for fast lookups in data files
#[derive(Debug)]
pub struct IndexFile {
    path: Utf8PathBuf,
    entries: BTreeMap<String, u64>, // key -> offset
    is_dirty: bool,
}

impl IndexFile {
    pub async fn create<P: AsRef<Utf8Path>>(path: P) -> SpandxResult<Self> {
        let path = path.as_ref().to_path_buf();
        
        // Ensure parent directory exists
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        Ok(Self {
            path,
            entries: BTreeMap::new(),
            is_dirty: false,
        })
    }

    pub async fn open<P: AsRef<Utf8Path>>(path: P) -> SpandxResult<Self> {
        let path = path.as_ref().to_path_buf();
        let mut entries = BTreeMap::new();
        
        if path.exists() {
            let mut file = File::open(&path).await?;
            
            // Read the number of entries (4 bytes, little-endian)
            let mut count_bytes = [0u8; 4];
            file.read_exact(&mut count_bytes).await?;
            let entry_count = u32::from_le_bytes(count_bytes) as usize;
            
            debug!("Loading index file {} with {} entries", path, entry_count);
            
            // Read each entry: key_length (4 bytes) + key + offset (8 bytes)
            for _ in 0..entry_count {
                // Read key length
                let mut key_len_bytes = [0u8; 4];
                file.read_exact(&mut key_len_bytes).await?;
                let key_len = u32::from_le_bytes(key_len_bytes) as usize;
                
                // Read key
                let mut key_bytes = vec![0u8; key_len];
                file.read_exact(&mut key_bytes).await?;
                let key = String::from_utf8(key_bytes)?;
                
                // Read offset
                let mut offset_bytes = [0u8; 8];
                file.read_exact(&mut offset_bytes).await?;
                let offset = u64::from_le_bytes(offset_bytes);
                
                entries.insert(key, offset);
            }
        }
        
        Ok(Self {
            path,
            entries,
            is_dirty: false,
        })
    }

    pub async fn add_entry(&mut self, key: &str, offset: u64) -> SpandxResult<()> {
        self.entries.insert(key.to_string(), offset);
        self.is_dirty = true;
        Ok(())
    }

    pub async fn find_offset(&self, key: &str) -> SpandxResult<Option<u64>> {
        Ok(self.entries.get(key).copied())
    }

    pub async fn finalize(&mut self) -> SpandxResult<()> {
        if !self.is_dirty {
            return Ok(());
        }
        
        let mut file = OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(&self.path)
            .await?;
        
        // Write number of entries
        let entry_count = self.entries.len() as u32;
        file.write_all(&entry_count.to_le_bytes()).await?;
        
        // Write each entry
        for (key, offset) in &self.entries {
            // Write key length
            let key_bytes = key.as_bytes();
            let key_len = key_bytes.len() as u32;
            file.write_all(&key_len.to_le_bytes()).await?;
            
            // Write key
            file.write_all(key_bytes).await?;
            
            // Write offset
            file.write_all(&offset.to_le_bytes()).await?;
        }
        
        file.flush().await?;
        self.is_dirty = false;
        
        debug!("Finalized index file {} with {} entries", self.path, self.entries.len());
        Ok(())
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    pub fn keys(&self) -> impl Iterator<Item = &String> {
        self.entries.keys()
    }

    pub fn path(&self) -> &Utf8Path {
        &self.path
    }

    /// Get range of keys for binary search optimization
    pub fn key_range(&self) -> Option<(&str, &str)> {
        if self.entries.is_empty() {
            None
        } else {
            let first_key = self.entries.keys().next().unwrap();
            let last_key = self.entries.keys().last().unwrap();
            Some((first_key, last_key))
        }
    }

    /// Find all keys with a given prefix
    pub fn find_keys_with_prefix(&self, prefix: &str) -> Vec<&String> {
        self.entries
            .keys()
            .filter(|key| key.starts_with(prefix))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_index_file_create_and_add() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.idx")).unwrap();
        
        let mut index_file = IndexFile::create(&file_path).await.unwrap();
        
        index_file.add_entry("rails:7.0.0", 0).await.unwrap();
        index_file.add_entry("sinatra:2.0.0", 42).await.unwrap();
        index_file.add_entry("rack:2.0.0", 100).await.unwrap();
        
        assert_eq!(index_file.len(), 3);
        assert!(!index_file.is_empty());
        
        let offset = index_file.find_offset("sinatra:2.0.0").await.unwrap();
        assert_eq!(offset, Some(42));
        
        let no_offset = index_file.find_offset("unknown:1.0.0").await.unwrap();
        assert_eq!(no_offset, None);
    }

    #[tokio::test]
    async fn test_index_file_finalize_and_reload() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.idx")).unwrap();
        
        // Create and populate index
        {
            let mut index_file = IndexFile::create(&file_path).await.unwrap();
            index_file.add_entry("rails:7.0.0", 0).await.unwrap();
            index_file.add_entry("sinatra:2.0.0", 42).await.unwrap();
            index_file.add_entry("rack:2.0.0", 100).await.unwrap();
            index_file.finalize().await.unwrap();
        }
        
        // Reload and verify
        {
            let index_file = IndexFile::open(&file_path).await.unwrap();
            assert_eq!(index_file.len(), 3);
            
            let offset = index_file.find_offset("sinatra:2.0.0").await.unwrap();
            assert_eq!(offset, Some(42));
            
            let offset = index_file.find_offset("rack:2.0.0").await.unwrap();
            assert_eq!(offset, Some(100));
        }
    }

    #[tokio::test]
    async fn test_index_file_sorted_order() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.idx")).unwrap();
        
        let mut index_file = IndexFile::create(&file_path).await.unwrap();
        
        // Add entries in non-alphabetical order
        index_file.add_entry("zebra:1.0.0", 200).await.unwrap();
        index_file.add_entry("apple:1.0.0", 0).await.unwrap();
        index_file.add_entry("banana:1.0.0", 100).await.unwrap();
        
        let keys: Vec<&String> = index_file.keys().collect();
        assert_eq!(keys, vec!["apple:1.0.0", "banana:1.0.0", "zebra:1.0.0"]);
        
        let range = index_file.key_range().unwrap();
        assert_eq!(range, ("apple:1.0.0", "zebra:1.0.0"));
    }

    #[tokio::test]
    async fn test_index_file_prefix_search() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.idx")).unwrap();
        
        let mut index_file = IndexFile::create(&file_path).await.unwrap();
        
        index_file.add_entry("rails:6.0.0", 0).await.unwrap();
        index_file.add_entry("rails:7.0.0", 50).await.unwrap();
        index_file.add_entry("rake:13.0.0", 100).await.unwrap();
        index_file.add_entry("sinatra:2.0.0", 150).await.unwrap();
        
        let rails_keys = index_file.find_keys_with_prefix("rails:");
        assert_eq!(rails_keys.len(), 2);
        assert!(rails_keys.contains(&&"rails:6.0.0".to_string()));
        assert!(rails_keys.contains(&&"rails:7.0.0".to_string()));
        
        let sinatra_keys = index_file.find_keys_with_prefix("sinatra:");
        assert_eq!(sinatra_keys.len(), 1);
        assert!(sinatra_keys.contains(&&"sinatra:2.0.0".to_string()));
        
        let unknown_keys = index_file.find_keys_with_prefix("unknown:");
        assert_eq!(unknown_keys.len(), 0);
    }

    #[tokio::test]
    async fn test_index_file_empty() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("empty.idx")).unwrap();
        
        let index_file = IndexFile::create(&file_path).await.unwrap();
        
        assert!(index_file.is_empty());
        assert_eq!(index_file.len(), 0);
        assert!(index_file.key_range().is_none());
        
        let no_offset = index_file.find_offset("anything").await.unwrap();
        assert_eq!(no_offset, None);
    }
}