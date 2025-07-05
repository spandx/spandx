use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug)]
pub struct ApkParser;

impl ApkParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "installed"
    }
}

impl Default for ApkParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for ApkParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "apk"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["installed"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing APK installed file at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let mut dependencies = DependencyCollection::new();
        let mut current_package = HashMap::new();
        
        for line in content.lines() {
            if line.trim().is_empty() {
                // End of package, create dependency if we have the required fields
                if let Some(dependency) = self.create_dependency_from_package(path, &current_package)? {
                    dependencies.add(dependency);
                }
                current_package.clear();
            } else {
                // Parse key:value line
                if let Some((key, value)) = line.split_once(':') {
                    current_package.insert(key.to_string(), value.to_string());
                }
            }
        }
        
        // Handle last package if file doesn't end with empty line
        if !current_package.is_empty() {
            if let Some(dependency) = self.create_dependency_from_package(path, &current_package)? {
                dependencies.add(dependency);
            }
        }
        
        debug!("Found {} dependencies in APK installed file", dependencies.len());
        Ok(dependencies)
    }
}

impl ApkParser {
    fn create_dependency_from_package(
        &self,
        path: &Utf8Path,
        package: &HashMap<String, String>,
    ) -> ParserResult<Option<Dependency>> {
        // Extract package name (P field)
        let package_name = package.get("P")
            .cloned()
            .unwrap_or_default();
        
        // Extract version (V field)
        let version = package.get("V")
            .cloned()
            .unwrap_or_default();
        
        if package_name.is_empty() || version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Store all APK fields as metadata
        for (key, value) in package {
            match key.as_str() {
                "P" => {}, // Package name, already used
                "V" => {}, // Version, already used
                "C" => { meta.insert("checksum".to_string(), value.clone()); },
                "A" => { meta.insert("architecture".to_string(), value.clone()); },
                "S" => { meta.insert("size".to_string(), value.clone()); },
                "I" => { meta.insert("installed_size".to_string(), value.clone()); },
                "T" => { meta.insert("description".to_string(), value.clone()); },
                "U" => { meta.insert("url".to_string(), value.clone()); },
                "L" => { meta.insert("license".to_string(), value.clone()); },
                "o" => { meta.insert("origin".to_string(), value.clone()); },
                "m" => { meta.insert("maintainer".to_string(), value.clone()); },
                "t" => { meta.insert("build_time".to_string(), value.clone()); },
                "D" => { meta.insert("depends".to_string(), value.clone()); },
                "p" => { meta.insert("provides".to_string(), value.clone()); },
                "r" => { meta.insert("replaces".to_string(), value.clone()); },
                "i" => { meta.insert("install_if".to_string(), value.clone()); },
                _ => {
                    meta.insert(key.clone(), value.clone());
                }
            }
        }
        
        let mut dependency = Dependency::new(package_name, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}