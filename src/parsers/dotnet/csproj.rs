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
pub struct CsprojParser;

impl CsprojParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename.ends_with(".csproj") || filename.ends_with(".props")
    }
}

impl Default for CsprojParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for CsprojParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "csproj"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["*.csproj", "*.props"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing .csproj/.props at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let document = Document::parse(&content)
            .map_err(|e| ParserError::XmlError(e.to_string()))?;
        
        let mut dependencies = DependencyCollection::new();
        
        let root = document.root_element();
        
        // Find all PackageReference and GlobalPackageReference nodes
        self.parse_package_references(&root, path, &mut dependencies)?;
        
        debug!("Found {} dependencies in .csproj/.props", dependencies.len());
        Ok(dependencies)
    }
}

impl CsprojParser {
    fn parse_package_references(
        &self,
        node: &Node,
        path: &Utf8Path,
        dependencies: &mut DependencyCollection,
    ) -> ParserResult<()> {
        // Recursively search for PackageReference and GlobalPackageReference
        if node.has_tag_name("PackageReference") || node.has_tag_name("GlobalPackageReference") {
            if let Some(dependency) = self.create_dependency_from_package_reference(path, node)? {
                dependencies.add(dependency);
            }
        }
        
        // Continue searching child nodes
        for child in node.children() {
            self.parse_package_references(&child, path, dependencies)?;
        }
        
        Ok(())
    }
    
    fn create_dependency_from_package_reference(
        &self,
        path: &Utf8Path,
        node: &Node,
    ) -> ParserResult<Option<Dependency>> {
        // Extract package name from Include or Update attribute
        let package_name = node.attribute("Include")
            .or_else(|| node.attribute("Update"))
            .unwrap_or("")
            .to_string();
        
        if package_name.is_empty() {
            return Ok(None);
        }
        
        // Extract version from Version attribute or child element
        let mut version = node.attribute("Version")
            .unwrap_or("")
            .to_string();
        
        // If no version attribute, look for Version child element
        if version.is_empty() {
            for child in node.children() {
                if child.has_tag_name("Version") {
                    if let Some(text) = child.text() {
                        version = text.trim().to_string();
                        break;
                    }
                }
            }
        }
        
        if version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        // Extract additional metadata from attributes
        if let Some(private_assets) = node.attribute("PrivateAssets") {
            meta.insert("private_assets".to_string(), private_assets.to_string());
        }
        
        if let Some(include_assets) = node.attribute("IncludeAssets") {
            meta.insert("include_assets".to_string(), include_assets.to_string());
        }
        
        if let Some(exclude_assets) = node.attribute("ExcludeAssets") {
            meta.insert("exclude_assets".to_string(), exclude_assets.to_string());
        }
        
        // Extract metadata from child elements
        for child in node.children() {
            if let Some(text) = child.text() {
                let text = text.trim();
                if !text.is_empty() {
                    match child.tag_name().name() {
                        "PrivateAssets" => {
                            meta.insert("private_assets".to_string(), text.to_string());
                        }
                        "IncludeAssets" => {
                            meta.insert("include_assets".to_string(), text.to_string());
                        }
                        "ExcludeAssets" => {
                            meta.insert("exclude_assets".to_string(), text.to_string());
                        }
                        "Condition" => {
                            meta.insert("condition".to_string(), text.to_string());
                        }
                        _ => {}
                    }
                }
            }
        }
        
        // Check for Condition attribute
        if let Some(condition) = node.attribute("Condition") {
            meta.insert("condition".to_string(), condition.to_string());
        }
        
        let mut dependency = Dependency::new(package_name, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}