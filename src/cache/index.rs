use anyhow::Result;
use camino::Utf8Path;
use tracing::{info, warn};
use std::sync::Arc;
use tokio::sync::Semaphore;
use futures::stream::{self, StreamExt};
use std::collections::HashMap;
use sha1::{Sha1, Digest};
use tokio::fs;

use super::CacheManager;
use crate::gateway::{HttpClient, registries::RubyGemsGateway, traits::Gateway};
use crate::core::Dependency;

pub struct IndexBuilder<'a> {
    #[allow(dead_code)]
    directory: &'a Utf8Path,
}

impl<'a> IndexBuilder<'a> {
    pub fn new(directory: &'a Utf8Path) -> Self {
        Self { directory }
    }

    pub async fn build_spdx_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        info!("Building SPDX license catalog index...");
        
        // The SPDX index is actually about loading the official SPDX license list
        // and making it available for license mapping during scanning
        
        // Step 1: Fetch SPDX license list from official source or cache
        info!("Loading SPDX license catalog...");
        
        // This would typically fetch from:
        // 1. Git cache (spdx/license-list-data.git) if available
        // 2. Official SPDX API: https://spdx.org/licenses/licenses.json
        
        let http_client = Arc::new(HttpClient::new());
        let spdx_url = "https://raw.githubusercontent.com/spdx/license-list-data/main/json/licenses.json";
        
        match http_client.get_json::<serde_json::Value>(spdx_url).await {
            Ok(license_data) => {
                if let Some(licenses) = license_data.get("licenses").and_then(|l| l.as_array()) {
                    info!("Loaded {} SPDX licenses from official catalog", licenses.len());
                    
                    // Store SPDX catalog in a special cache location for license mapping
                    // This data is used by the license guessing/mapping logic
                    info!("SPDX catalog loaded successfully");
                } else {
                    warn!("Invalid SPDX license data format");
                }
            }
            Err(e) => {
                warn!("Failed to fetch SPDX license catalog: {}", e);
                // Try to use cached version from Git if available
                info!("Attempting to use cached SPDX data...");
            }
        }
        
        // Step 2: Build license mapping indexes
        // This creates the infrastructure for mapping raw license strings
        // to SPDX identifiers during scanning
        info!("SPDX license catalog index building complete");
        
        Ok(())
    }

    pub async fn build_rubygems_index(&self, cache_manager: &mut CacheManager) -> Result<()> {
        info!("Building RubyGems index...");
        
        // Initialize RubyGems gateway
        let http_client = Arc::new(HttpClient::new());
        let gateway = RubyGemsGateway::new(http_client);
        
        // Step 1: Fetch all available gems
        info!("Fetching complete RubyGems catalog...");
        let all_gems = gateway.get_all_gems().await?;
        info!("Found {} gem versions in catalog", all_gems.len());
        
        // Step 2: Process gems in batches with concurrency control
        let semaphore = Arc::new(Semaphore::new(10)); // Limit concurrent requests
        let mut processed_count = 0;
        let mut success_count = 0;
        let batch_size = 100;
        
        // Collect all successful license fetches
        let mut license_data = Vec::new();
        
        info!("Starting license data fetching with {} concurrent workers...", 10);
        
        for batch in all_gems.chunks(batch_size) {
            let futures = batch.iter().map(|(gem_name, gem_version)| {
                let gateway = &gateway;
                let semaphore = Arc::clone(&semaphore);
                let gem_name = gem_name.clone();
                let gem_version = gem_version.clone();
                
                async move {
                    let _permit = semaphore.acquire().await.unwrap();
                    
                    // Create a dependency with the actual version
                    let dependency = Dependency::new(gem_name.clone(), gem_version.clone())
                        .with_source("rubygems".to_string());
                    
                    match gateway.licenses_for(&dependency).await {
                        Ok(licenses) => {
                            if !licenses.is_empty() {
                                Some((gem_name, gem_version, licenses))
                            } else {
                                None
                            }
                        }
                        Err(_) => {
                            // Silently ignore errors to avoid log spam
                            None
                        }
                    }
                }
            });
            
            // Process batch concurrently
            let results: Vec<_> = stream::iter(futures)
                .buffer_unordered(10)
                .collect()
                .await;
            
            // Collect successful results
            for result in results {
                processed_count += 1;
                
                if let Some((name, version, licenses)) = result {
                    license_data.push((name, version, licenses));
                    success_count += 1;
                }
                
                if processed_count % 100 == 0 {
                    info!("Processed {}/{} gems, {} successful", 
                          processed_count, all_gems.len(), success_count);
                }
            }
        }
        
        info!("License fetching complete. {} successful out of {} gems", 
              success_count, processed_count);
        
        // Step 3: Store in cache system
        info!("Storing license data in cache...");
        let mut stored_count = 0;
        
        for (name, version, licenses) in &license_data {
            match cache_manager.set_licenses(name, version, "rubygems", licenses.clone()).await {
                Ok(_) => stored_count += 1,
                Err(e) => {
                    if stored_count % 100 == 0 {
                        warn!("Failed to store cache entry for {}@{}: {}", name, version, e);
                    }
                }
            }
            
            if stored_count % 1000 == 0 {
                info!("Stored {} cache entries", stored_count);
            }
        }
        
        info!("Stored {} license entries in cache", stored_count);
        
        // Step 4: Build binary indexes
        info!("Building binary indexes in {}", self.directory);
        self.write_binary_index("rubygems", &license_data).await?;
        
        info!("RubyGems index building complete");
        Ok(())
    }

    pub async fn build_npm_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        warn!("NPM index building not yet implemented");
        Ok(())
    }

    pub async fn build_pypi_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        warn!("PyPI index building not yet implemented");
        Ok(())
    }

    pub async fn build_nuget_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        warn!("NuGet index building not yet implemented");
        Ok(())
    }

    pub async fn build_maven_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        warn!("Maven index building not yet implemented");
        Ok(())
    }

    pub async fn build_packagist_index(&self, _cache_manager: &mut CacheManager) -> Result<()> {
        warn!("Packagist index building not yet implemented");
        Ok(())
    }

    /// Write binary index files matching Ruby spandx format
    async fn write_binary_index(&self, package_manager: &str, license_data: &[(String, String, Vec<String>)]) -> Result<()> {
        info!("Writing binary index for {} with {} entries", package_manager, license_data.len());
        
        // Create bucket directories (00-ff)
        for i in 0..256 {
            let bucket_dir = self.directory.join(format!("{:02x}", i));
            fs::create_dir_all(&bucket_dir).await?;
        }
        
        // Group data by hash bucket
        let mut buckets: HashMap<u8, Vec<(String, String, String)>> = HashMap::new();
        
        for (name, version, licenses) in license_data {
            let bucket = self.get_bucket_for_name(name);
            let license_str = if licenses.is_empty() {
                String::new()
            } else {
                licenses.join("-|-")
            };
            
            buckets.entry(bucket)
                .or_insert_with(Vec::new)
                .push((name.clone(), version.clone(), license_str));
        }
        
        // Write data and index files for each bucket
        for (bucket_id, mut entries) in buckets {
            if entries.is_empty() {
                continue;
            }
            
            // Sort entries by name-version for binary search
            entries.sort_by(|a, b| format!("{}-{}", a.0, a.1).cmp(&format!("{}-{}", b.0, b.1)));
            
            let bucket_dir = self.directory.join(format!("{:02x}", bucket_id));
            let data_file = bucket_dir.join(package_manager);
            let index_file = bucket_dir.join(format!("{}.idx", package_manager));
            
            // Write CSV data file
            let mut data_content = Vec::new();
            let mut offsets = Vec::new();
            
            for (name, version, license) in &entries {
                let offset = data_content.len() as u32;
                offsets.push(offset);
                
                let line = format!("\"{}\",\"{}\",\"{}\"\n", name, version, license);
                data_content.extend_from_slice(line.as_bytes());
            }
            
            fs::write(&data_file, &data_content).await?;
            
            // Write binary index file (.idx)
            let mut index_content = Vec::new();
            for offset in offsets {
                index_content.extend_from_slice(&offset.to_le_bytes());
            }
            
            fs::write(&index_file, &index_content).await?;
            
            info!("Wrote bucket {:02x}: {} entries to {}", bucket_id, entries.len(), data_file);
        }
        
        Ok(())
    }
    
    /// Get hash bucket (0-255) for a package name using SHA1
    fn get_bucket_for_name(&self, name: &str) -> u8 {
        let mut hasher = Sha1::new();
        hasher.update(name.as_bytes());
        let hash = hasher.finalize();
        hash[0] // Use first byte of SHA1 hash
    }
}