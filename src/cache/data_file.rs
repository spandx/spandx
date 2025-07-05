use crate::cache::cache::CacheEntry;
use crate::error::{SpandxError, SpandxResult};
use camino::{Utf8Path, Utf8PathBuf};
use tokio::fs::{File, OpenOptions};
use tokio::io::{AsyncBufReadExt, AsyncSeekExt, AsyncWriteExt, BufReader};
use tracing::{debug, warn};

/// Handles CSV data files containing package information
#[derive(Debug)]
pub struct DataFile {
    path: Utf8PathBuf,
    file: Option<File>,
    current_offset: u64,
}

impl DataFile {
    pub async fn create<P: AsRef<Utf8Path>>(path: P) -> SpandxResult<Self> {
        let path = path.as_ref().to_path_buf();
        
        // Ensure parent directory exists
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        let file = OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(&path)
            .await?;
            
        Ok(Self {
            path,
            file: Some(file),
            current_offset: 0,
        })
    }

    pub async fn open<P: AsRef<Utf8Path>>(path: P) -> SpandxResult<Self> {
        let path = path.as_ref().to_path_buf();
        
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .open(&path)
            .await?;
            
        Ok(Self {
            path,
            file: Some(file),
            current_offset: 0,
        })
    }

    pub fn current_offset(&self) -> u64 {
        self.current_offset
    }

    pub async fn append_entry(&mut self, entry: &CacheEntry) -> SpandxResult<()> {
        if let Some(ref mut file) = self.file {
            let csv_line = entry.to_csv_line();
            let line_with_newline = format!("{}\n", csv_line);
            
            file.write_all(line_with_newline.as_bytes()).await?;
            file.flush().await?;
            
            self.current_offset += line_with_newline.len() as u64;
            
            debug!("Appended entry to {}: {}", self.path, csv_line);
        } else {
            return Err(SpandxError::CacheError {
                operation: "append_entry".to_string(),
                source: Some(Box::new(std::io::Error::new(
                    std::io::ErrorKind::InvalidInput,
                    "Data file not open for writing"
                )))
            });
        }
        
        Ok(())
    }

    pub async fn read_entry_at_offset(&self, offset: u64) -> SpandxResult<Option<CacheEntry>> {
        let file = File::open(&self.path).await?;
        let mut reader = BufReader::new(file);
        
        reader.seek(std::io::SeekFrom::Start(offset)).await?;
        
        let mut line = String::new();
        let bytes_read = reader.read_line(&mut line).await?;
        
        if bytes_read == 0 {
            return Ok(None);
        }
        
        // Remove trailing newline
        if line.ends_with('\n') {
            line.pop();
        }
        if line.ends_with('\r') {
            line.pop();
        }
        
        match CacheEntry::from_csv_line(&line) {
            Ok(entry) => Ok(Some(entry)),
            Err(e) => {
                warn!("Failed to parse CSV line at offset {}: {} - {}", offset, line, e);
                Ok(None)
            }
        }
    }

    pub async fn read_all_entries(&self) -> SpandxResult<Vec<CacheEntry>> {
        let file = File::open(&self.path).await?;
        let reader = BufReader::new(file);
        let mut lines = reader.lines();
        let mut entries = Vec::new();
        
        while let Some(line) = lines.next_line().await? {
            if !line.trim().is_empty() {
                match CacheEntry::from_csv_line(&line) {
                    Ok(entry) => entries.push(entry),
                    Err(e) => {
                        warn!("Failed to parse CSV line: {} - {}", line, e);
                    }
                }
            }
        }
        
        Ok(entries)
    }

    pub async fn count_entries(&self) -> SpandxResult<usize> {
        let file = File::open(&self.path).await?;
        let reader = BufReader::new(file);
        let mut lines = reader.lines();
        let mut count = 0;
        
        while let Some(line) = lines.next_line().await? {
            if !line.trim().is_empty() {
                count += 1;
            }
        }
        
        Ok(count)
    }

    pub async fn iterate_entries<F>(&self, mut callback: F) -> SpandxResult<()>
    where
        F: FnMut(&CacheEntry) -> bool, // Return false to stop iteration
    {
        let file = File::open(&self.path).await?;
        let reader = BufReader::new(file);
        let mut lines = reader.lines();
        
        while let Some(line) = lines.next_line().await? {
            if !line.trim().is_empty() {
                match CacheEntry::from_csv_line(&line) {
                    Ok(entry) => {
                        if !callback(&entry) {
                            break;
                        }
                    }
                    Err(e) => {
                        warn!("Failed to parse CSV line during iteration: {} - {}", line, e);
                    }
                }
            }
        }
        
        Ok(())
    }

    pub fn path(&self) -> &Utf8Path {
        &self.path
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_data_file_create_and_append() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.csv")).unwrap();
        
        let mut data_file = DataFile::create(&file_path).await.unwrap();
        
        let entry = CacheEntry::new(
            "rails".to_string(),
            "7.0.0".to_string(),
            vec!["MIT".to_string()],
        );
        
        let initial_offset = data_file.current_offset();
        data_file.append_entry(&entry).await.unwrap();
        
        assert!(data_file.current_offset() > initial_offset);
        assert!(file_path.exists());
    }

    #[tokio::test]
    async fn test_data_file_read_entry_at_offset() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.csv")).unwrap();
        
        let mut data_file = DataFile::create(&file_path).await.unwrap();
        
        let entry1 = CacheEntry::new(
            "rails".to_string(),
            "7.0.0".to_string(),
            vec!["MIT".to_string()],
        );
        let entry2 = CacheEntry::new(
            "sinatra".to_string(),
            "2.0.0".to_string(),
            vec!["MIT".to_string(), "Apache-2.0".to_string()],
        );
        
        let offset1 = data_file.current_offset();
        data_file.append_entry(&entry1).await.unwrap();
        
        let offset2 = data_file.current_offset();
        data_file.append_entry(&entry2).await.unwrap();
        
        // Read entries back
        let read_entry1 = data_file.read_entry_at_offset(offset1).await.unwrap().unwrap();
        let read_entry2 = data_file.read_entry_at_offset(offset2).await.unwrap().unwrap();
        
        assert_eq!(read_entry1, entry1);
        assert_eq!(read_entry2, entry2);
    }

    #[tokio::test]
    async fn test_data_file_read_all_entries() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.csv")).unwrap();
        
        let mut data_file = DataFile::create(&file_path).await.unwrap();
        
        let entries = vec![
            CacheEntry::new("rails".to_string(), "7.0.0".to_string(), vec!["MIT".to_string()]),
            CacheEntry::new("sinatra".to_string(), "2.0.0".to_string(), vec!["MIT".to_string()]),
            CacheEntry::new("rack".to_string(), "2.0.0".to_string(), vec!["MIT".to_string()]),
        ];
        
        for entry in &entries {
            data_file.append_entry(entry).await.unwrap();
        }
        
        let read_entries = data_file.read_all_entries().await.unwrap();
        assert_eq!(read_entries, entries);
    }

    #[tokio::test]
    async fn test_data_file_count_entries() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.csv")).unwrap();
        
        let mut data_file = DataFile::create(&file_path).await.unwrap();
        
        assert_eq!(data_file.count_entries().await.unwrap(), 0);
        
        data_file.append_entry(&CacheEntry::new("rails".to_string(), "7.0.0".to_string(), vec!["MIT".to_string()])).await.unwrap();
        assert_eq!(data_file.count_entries().await.unwrap(), 1);
        
        data_file.append_entry(&CacheEntry::new("sinatra".to_string(), "2.0.0".to_string(), vec!["MIT".to_string()])).await.unwrap();
        assert_eq!(data_file.count_entries().await.unwrap(), 2);
    }

    #[tokio::test]
    async fn test_data_file_iterate_entries() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = Utf8PathBuf::from_path_buf(temp_dir.path().join("test.csv")).unwrap();
        
        let mut data_file = DataFile::create(&file_path).await.unwrap();
        
        let entries = vec![
            CacheEntry::new("rails".to_string(), "7.0.0".to_string(), vec!["MIT".to_string()]),
            CacheEntry::new("sinatra".to_string(), "2.0.0".to_string(), vec!["MIT".to_string()]),
            CacheEntry::new("rack".to_string(), "2.0.0".to_string(), vec!["MIT".to_string()]),
        ];
        
        for entry in &entries {
            data_file.append_entry(entry).await.unwrap();
        }
        
        let mut collected_entries = Vec::new();
        data_file.iterate_entries(|entry| {
            collected_entries.push(entry.clone());
            true // Continue iteration
        }).await.unwrap();
        
        assert_eq!(collected_entries, entries);
        
        // Test early termination
        let mut limited_entries = Vec::new();
        data_file.iterate_entries(|entry| {
            limited_entries.push(entry.clone());
            limited_entries.len() < 2 // Stop after 2 entries
        }).await.unwrap();
        
        assert_eq!(limited_entries.len(), 2);
    }
}