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
pub struct ComposerParser;

impl ComposerParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "composer.lock"
    }
}

impl Default for ComposerParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for ComposerParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "composer"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["composer.lock"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing composer.lock at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let composer_lock: Value = serde_json::from_str(&content)
            .map_err(ParserError::JsonError)?;
        
        let mut dependencies = DependencyCollection::new();
        
        // Parse production packages
        if let Some(packages) = composer_lock.get("packages").and_then(|v| v.as_array()) {
            for package in packages {
                if let Some(dependency) = self.create_dependency(path, package, "production")? {
                    dependencies.add(dependency);
                }
            }
        }
        
        // Parse development packages
        if let Some(packages_dev) = composer_lock.get("packages-dev").and_then(|v| v.as_array()) {
            for package in packages_dev {
                if let Some(dependency) = self.create_dependency(path, package, "development")? {
                    dependencies.add(dependency);
                }
            }
        }
        
        debug!("Found {} dependencies in composer.lock", dependencies.len());
        Ok(dependencies)
    }
}

impl ComposerParser {
    fn create_dependency(
        &self,
        path: &Utf8Path,
        package: &Value,
        group: &str,
    ) -> ParserResult<Option<Dependency>> {
        let name = package
            .get("name")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        
        let version = package
            .get("version")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        
        if name.is_empty() || version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Add group information
        meta.insert("group".to_string(), group.to_string());
        
        // Extract type
        if let Some(pkg_type) = package.get("type").and_then(|v| v.as_str()) {
            meta.insert("type".to_string(), pkg_type.to_string());
        }
        
        // Extract description
        if let Some(description) = package.get("description").and_then(|v| v.as_str()) {
            meta.insert("description".to_string(), description.to_string());
        }
        
        // Extract homepage
        if let Some(homepage) = package.get("homepage").and_then(|v| v.as_str()) {
            meta.insert("homepage".to_string(), homepage.to_string());
        }
        
        // Extract keywords
        if let Some(keywords) = package.get("keywords").and_then(|v| v.as_array()) {
            let keyword_strings: Vec<String> = keywords
                .iter()
                .filter_map(|k| k.as_str())
                .map(|k| k.to_string())
                .collect();
            if !keyword_strings.is_empty() {
                meta.insert("keywords".to_string(), keyword_strings.join(","));
            }
        }
        
        // Extract license information
        if let Some(licenses) = package.get("license").and_then(|v| v.as_array()) {
            let license_strings: Vec<String> = licenses
                .iter()
                .filter_map(|l| l.as_str())
                .map(|l| l.to_string())
                .collect();
            if !license_strings.is_empty() {
                meta.insert("license".to_string(), license_strings.join(","));
            }
        }
        
        // Extract source information
        if let Some(source) = package.get("source").and_then(|v| v.as_object()) {
            if let Some(url) = source.get("url").and_then(|v| v.as_str()) {
                meta.insert("source_url".to_string(), url.to_string());
            }
            if let Some(reference) = source.get("reference").and_then(|v| v.as_str()) {
                meta.insert("source_reference".to_string(), reference.to_string());
            }
            if let Some(source_type) = source.get("type").and_then(|v| v.as_str()) {
                meta.insert("source_type".to_string(), source_type.to_string());
            }
        }
        
        // Extract distribution information
        if let Some(dist) = package.get("dist").and_then(|v| v.as_object()) {
            if let Some(url) = dist.get("url").and_then(|v| v.as_str()) {
                meta.insert("dist_url".to_string(), url.to_string());
            }
            if let Some(shasum) = dist.get("shasum").and_then(|v| v.as_str()) {
                meta.insert("dist_shasum".to_string(), shasum.to_string());
            }
            if let Some(dist_type) = dist.get("type").and_then(|v| v.as_str()) {
                meta.insert("dist_type".to_string(), dist_type.to_string());
            }
        }
        
        // Extract authors
        if let Some(authors) = package.get("authors").and_then(|v| v.as_array()) {
            let author_names: Vec<String> = authors
                .iter()
                .filter_map(|a| a.as_object())
                .filter_map(|a| a.get("name").and_then(|n| n.as_str()))
                .map(|n| n.to_string())
                .collect();
            if !author_names.is_empty() {
                meta.insert("authors".to_string(), author_names.join(","));
            }
        }
        
        // Extract time
        if let Some(time) = package.get("time").and_then(|v| v.as_str()) {
            meta.insert("time".to_string(), time.to_string());
        }
        
        let mut dependency = Dependency::new(name, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}