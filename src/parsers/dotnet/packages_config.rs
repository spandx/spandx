use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use roxmltree::{Document, Node};
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug)]
pub struct PackagesConfigParser;

impl PackagesConfigParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "packages.config"
    }
}

impl Default for PackagesConfigParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for PackagesConfigParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "packages_config"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["packages.config"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing packages.config at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let document = Document::parse(&content)
            .map_err(|e| ParserError::XmlError(e.to_string()))?;
        
        let mut dependencies = DependencyCollection::new();
        
        let root = document.root_element();
        
        // Find all package nodes
        self.parse_packages(&root, path, &mut dependencies)?;
        
        debug!("Found {} dependencies in packages.config", dependencies.len());
        Ok(dependencies)
    }
}

impl PackagesConfigParser {
    fn parse_packages(
        &self,
        node: &Node,
        path: &Utf8Path,
        dependencies: &mut DependencyCollection,
    ) -> ParserResult<()> {
        // Look for package elements
        if node.has_tag_name("package") {
            if let Some(dependency) = self.create_dependency_from_package(path, node)? {
                dependencies.add(dependency);
            }
        }
        
        // Continue searching child nodes
        for child in node.children() {
            self.parse_packages(&child, path, dependencies)?;
        }
        
        Ok(())
    }
    
    fn create_dependency_from_package(
        &self,
        path: &Utf8Path,
        node: &Node,
    ) -> ParserResult<Option<Dependency>> {
        // Extract package id and version from attributes
        let package_id = node.attribute("id")
            .unwrap_or("")
            .to_string();
        
        let mut version = node.attribute("version")
            .unwrap_or("")
            .to_string();
        
        // If no version attribute, look for version child element
        if version.is_empty() {
            for child in node.children() {
                if child.has_tag_name("version") {
                    if let Some(text) = child.text() {
                        version = text.trim().to_string();
                        break;
                    }
                }
            }
        }
        
        if package_id.is_empty() || version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Extract additional metadata from attributes
        if let Some(target_framework) = node.attribute("targetFramework") {
            meta.insert("target_framework".to_string(), target_framework.to_string());
        }
        
        if let Some(development_dependency) = node.attribute("developmentDependency") {
            meta.insert("development_dependency".to_string(), development_dependency.to_string());
        }
        
        if let Some(require_reinstallation) = node.attribute("requireReinstallation") {
            meta.insert("require_reinstallation".to_string(), require_reinstallation.to_string());
        }
        
        // Extract metadata from child elements
        for child in node.children() {
            if let Some(text) = child.text() {
                let text = text.trim();
                if !text.is_empty() {
                    match child.tag_name().name() {
                        "targetFramework" => {
                            meta.insert("target_framework".to_string(), text.to_string());
                        }
                        "developmentDependency" => {
                            meta.insert("development_dependency".to_string(), text.to_string());
                        }
                        "requireReinstallation" => {
                            meta.insert("require_reinstallation".to_string(), text.to_string());
                        }
                        _ => {}
                    }
                }
            }
        }
        
        let mut dependency = Dependency::new(package_id, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}