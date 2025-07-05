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
pub struct PipfileLockParser;

impl PipfileLockParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename.starts_with("Pipfile") && filename.ends_with(".lock")
    }
}

impl Default for PipfileLockParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for PipfileLockParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "pipfile"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["Pipfile.lock", "Pipfile*.lock"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing Pipfile.lock at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let pipfile_lock: Value = serde_json::from_str(&content)
            .map_err(ParserError::JsonError)?;
        
        let mut dependencies = DependencyCollection::new();
        
        // Parse dependencies from both "default" and "develop" groups
        let groups = ["default", "develop"];
        for group in &groups {
            if let Some(group_deps) = pipfile_lock.get(group).and_then(|v| v.as_object()) {
                for (name, metadata) in group_deps {
                    if let Some(dependency) = self.create_dependency(path, name, metadata, group)? {
                        dependencies.add(dependency);
                    }
                }
            }
        }
        
        debug!("Found {} dependencies in Pipfile.lock", dependencies.len());
        Ok(dependencies)
    }
}

impl PipfileLockParser {
    fn create_dependency(
        &self,
        path: &Utf8Path,
        name: &str,
        metadata: &Value,
        group: &str,
    ) -> ParserResult<Option<Dependency>> {
        let version = metadata
            .get("version")
            .and_then(|v| v.as_str())
            .map(|v| self.canonicalize_version(v))
            .unwrap_or_default();
        
        if version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Add group information
        meta.insert("group".to_string(), group.to_string());
        
        // Extract hashes
        if let Some(hashes) = metadata.get("hashes").and_then(|v| v.as_array()) {
            let hash_strings: Vec<String> = hashes
                .iter()
                .filter_map(|h| h.as_str())
                .map(|h| h.to_string())
                .collect();
            if !hash_strings.is_empty() {
                meta.insert("hashes".to_string(), hash_strings.join(","));
            }
        }
        
        // Extract index
        if let Some(index) = metadata.get("index").and_then(|v| v.as_str()) {
            meta.insert("index".to_string(), index.to_string());
        }
        
        // Extract markers (environment markers)
        if let Some(markers) = metadata.get("markers").and_then(|v| v.as_str()) {
            meta.insert("markers".to_string(), markers.to_string());
        }
        
        // Extract extras
        if let Some(extras) = metadata.get("extras").and_then(|v| v.as_array()) {
            let extra_strings: Vec<String> = extras
                .iter()
                .filter_map(|e| e.as_str())
                .map(|e| e.to_string())
                .collect();
            if !extra_strings.is_empty() {
                meta.insert("extras".to_string(), extra_strings.join(","));
            }
        }
        
        let mut dependency = Dependency::new(name.to_string(), version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
    
    fn canonicalize_version(&self, version: &str) -> String {
        // Remove == prefix from version string
        version.strip_prefix("==").unwrap_or(version).to_string()
    }
}