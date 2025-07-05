use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use serde_json::Value;
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug)]
pub struct NpmParser;

impl NpmParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "package-lock.json"
    }
}

impl Default for NpmParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for NpmParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "npm"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["package-lock.json"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing package-lock.json at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let package_lock: Value = serde_json::from_str(&content)
            .map_err(ParserError::JsonError)?;
        
        let mut dependencies = DependencyCollection::new();
        
        if let Some(deps) = package_lock.get("dependencies").and_then(|v| v.as_object()) {
            for (name, metadata) in deps {
                if let Some(dependency) = self.create_dependency(path, name, metadata)? {
                    dependencies.add(dependency);
                }
            }
        }
        
        debug!("Found {} dependencies in package-lock.json", dependencies.len());
        Ok(dependencies)
    }
}

impl NpmParser {
    fn create_dependency(
        &self,
        path: &Utf8Path,
        name: &str,
        metadata: &Value,
    ) -> ParserResult<Option<Dependency>> {
        let version = metadata
            .get("version")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        
        if version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Extract resolved URL
        if let Some(resolved) = metadata.get("resolved").and_then(|v| v.as_str()) {
            meta.insert("resolved".to_string(), resolved.to_string());
        }
        
        // Extract integrity hash
        if let Some(integrity) = metadata.get("integrity").and_then(|v| v.as_str()) {
            meta.insert("integrity".to_string(), integrity.to_string());
        }
        
        // Extract dev flag
        if let Some(dev) = metadata.get("dev").and_then(|v| v.as_bool()) {
            meta.insert("dev".to_string(), dev.to_string());
        }
        
        // Extract optional flag
        if let Some(optional) = metadata.get("optional").and_then(|v| v.as_bool()) {
            meta.insert("optional".to_string(), optional.to_string());
        }
        
        // Extract bundled flag
        if let Some(bundled) = metadata.get("bundled").and_then(|v| v.as_bool()) {
            meta.insert("bundled".to_string(), bundled.to_string());
        }
        
        let mut dependency = Dependency::new(name.to_string(), version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}