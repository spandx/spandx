use anyhow::Result;
use camino::Utf8Path;
use tracing::warn;

use super::CacheManager;

pub struct IndexBuilder<'a> {
    #[allow(dead_code)]
    directory: &'a Utf8Path,
}

impl<'a> IndexBuilder<'a> {
    pub fn new(directory: &'a Utf8Path) -> Self {
        Self { directory }
    }

    pub async fn build_spdx_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("SPDX index building not yet implemented");
        Ok(())
    }

    pub async fn build_rubygems_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("Ruby gems index building not yet implemented");
        Ok(())
    }

    pub async fn build_npm_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("NPM index building not yet implemented");
        Ok(())
    }

    pub async fn build_pypi_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("PyPI index building not yet implemented");
        Ok(())
    }

    pub async fn build_nuget_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("NuGet index building not yet implemented");
        Ok(())
    }

    pub async fn build_maven_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("Maven index building not yet implemented");
        Ok(())
    }

    pub async fn build_packagist_index(&self, _cache_manager: &CacheManager) -> Result<()> {
        warn!("Packagist index building not yet implemented");
        Ok(())
    }
}