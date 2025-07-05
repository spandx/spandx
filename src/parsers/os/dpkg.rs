use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug)]
pub struct DpkgParser;

impl DpkgParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "status"
    }
}

impl Default for DpkgParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for DpkgParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "dpkg"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["status"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing DPKG status file at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let mut dependencies = DependencyCollection::new();
        let mut current_package = HashMap::new();
        let mut lines = content.lines().peekable();
        
        while let Some(line) = lines.next() {
            if line.trim().is_empty() {
                // End of package, create dependency if we have the required fields
                if let Some(dependency) = self.create_dependency_from_package(path, &current_package)? {
                    dependencies.add(dependency);
                }
                current_package.clear();
            } else {
                // Parse Debian control format
                self.parse_control_line(line, &mut lines, &mut current_package);
            }
        }
        
        // Handle last package if file doesn't end with empty line
        if !current_package.is_empty() {
            if let Some(dependency) = self.create_dependency_from_package(path, &current_package)? {
                dependencies.add(dependency);
            }
        }
        
        debug!("Found {} dependencies in DPKG status file", dependencies.len());
        Ok(dependencies)
    }
}

impl DpkgParser {
    fn parse_control_line(
        &self,
        line: &str,
        lines: &mut std::iter::Peekable<std::str::Lines>,
        package: &mut HashMap<String, String>,
    ) {
        if line.starts_with(' ') || line.starts_with('\t') {
            // Continuation line - find the last key and append
            if let Some((last_key, _)) = package.iter().last() {
                let last_key = last_key.clone();
                let existing_value = package.get(&last_key).unwrap_or(&String::new()).clone();
                let new_value = if existing_value.is_empty() {
                    line.to_string()
                } else {
                    format!("{}\n{}", existing_value, line)
                };
                package.insert(last_key, new_value);
            }
        } else if let Some((key, value)) = line.split_once(':') {
            let key = key.trim().to_string();
            let mut value = value.trim().to_string();
            
            // Handle multi-line values by reading continuation lines
            while let Some(next_line) = lines.peek() {
                if next_line.starts_with(' ') || next_line.starts_with('\t') {
                    let continuation = lines.next().unwrap();
                    value.push('\n');
                    value.push_str(continuation);
                } else {
                    break;
                }
            }
            
            package.insert(key, value);
        }
    }
    
    fn create_dependency_from_package(
        &self,
        path: &Utf8Path,
        package: &HashMap<String, String>,
    ) -> ParserResult<Option<Dependency>> {
        // Extract package name
        let package_name = package.get("Package")
            .cloned()
            .unwrap_or_default();
        
        // Extract version
        let version = package.get("Version")
            .cloned()
            .unwrap_or_default();
        
        if package_name.is_empty() || version.is_empty() {
            return Ok(None);
        }
        
        // Check if package is installed (not just configured)
        if let Some(status) = package.get("Status") {
            if !status.contains("install ok installed") {
                return Ok(None); // Skip packages that aren't fully installed
            }
        }
        
        let mut meta = HashMap::new();
        
        // Store all DPKG fields as metadata
        for (key, value) in package {
            match key.as_str() {
                "Package" => {}, // Package name, already used
                "Version" => {}, // Version, already used
                "Status" => { meta.insert("status".to_string(), value.clone()); },
                "Priority" => { meta.insert("priority".to_string(), value.clone()); },
                "Section" => { meta.insert("section".to_string(), value.clone()); },
                "Installed-Size" => { meta.insert("installed_size".to_string(), value.clone()); },
                "Maintainer" => { meta.insert("maintainer".to_string(), value.clone()); },
                "Architecture" => { meta.insert("architecture".to_string(), value.clone()); },
                "Multi-Arch" => { meta.insert("multi_arch".to_string(), value.clone()); },
                "Depends" => { meta.insert("depends".to_string(), value.clone()); },
                "Pre-Depends" => { meta.insert("pre_depends".to_string(), value.clone()); },
                "Recommends" => { meta.insert("recommends".to_string(), value.clone()); },
                "Suggests" => { meta.insert("suggests".to_string(), value.clone()); },
                "Conflicts" => { meta.insert("conflicts".to_string(), value.clone()); },
                "Breaks" => { meta.insert("breaks".to_string(), value.clone()); },
                "Replaces" => { meta.insert("replaces".to_string(), value.clone()); },
                "Provides" => { meta.insert("provides".to_string(), value.clone()); },
                "Description" => { meta.insert("description".to_string(), value.clone()); },
                "Homepage" => { meta.insert("homepage".to_string(), value.clone()); },
                "Source" => { meta.insert("source".to_string(), value.clone()); },
                "Essential" => { meta.insert("essential".to_string(), value.clone()); },
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