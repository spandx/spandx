use anyhow::Result;
use camino::Utf8Path;
use tracing::{info, warn};
use std::sync::Arc;
use tokio::sync::Semaphore;
use futures::stream::{self, StreamExt};

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
        warn!("SPDX index building not yet implemented");
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
        info!("Found {} gems in catalog", all_gems.len());
        
        // Step 2: Process gems in batches with concurrency control
        let semaphore = Arc::new(Semaphore::new(10)); // Limit concurrent requests
        let mut processed_count = 0;
        let mut success_count = 0;
        let batch_size = 100;
        
        // Collect all successful license fetches
        let mut license_data = Vec::new();
        
        info!("Starting license data fetching with {} concurrent workers...", 10);
        
        for batch in all_gems.chunks(batch_size) {
            let futures = batch.iter().map(|gem_name| {
                let gateway = &gateway;
                let semaphore = Arc::clone(&semaphore);
                let gem_name = gem_name.clone();
                
                async move {
                    let _permit = semaphore.acquire().await.unwrap();
                    
                    // Create a dummy dependency to use the gateway
                    let dependency = Dependency::new(gem_name.clone(), "latest".to_string())
                        .with_source("rubygems".to_string());
                    
                    match gateway.licenses_for(&dependency).await {
                        Ok(licenses) => {
                            if !licenses.is_empty() {
                                // For now, we don't know the exact version, so we'll use "latest"
                                // In a full implementation, we'd fetch all versions
                                Some((gem_name, "latest".to_string(), licenses))
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
        
        for (name, version, licenses) in license_data {
            match cache_manager.set_licenses(&name, &version, "rubygems", licenses).await {
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
        info!("Binary index generation would happen here");
        
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
}