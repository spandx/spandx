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
pub struct MavenParser;

impl MavenParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "pom.xml"
    }
}

impl Default for MavenParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for MavenParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "maven"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["pom.xml"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing pom.xml at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let document = Document::parse(&content)
            .map_err(|e| ParserError::XmlError(e.to_string()))?;
        
        let mut dependencies = DependencyCollection::new();
        
        // Find all dependency nodes in the project
        let root = document.root_element();
        if let Some(dependencies_node) = self.find_dependencies_node(&root) {
            for dependency_node in dependencies_node.children().filter(|n| n.has_tag_name("dependency")) {
                if let Some(dependency) = self.create_dependency(path, &dependency_node)? {
                    dependencies.add(dependency);
                }
            }
        }
        
        debug!("Found {} dependencies in pom.xml", dependencies.len());
        Ok(dependencies)
    }
}

impl MavenParser {
    fn find_dependencies_node<'a>(&self, root: &'a Node) -> Option<Node<'a, 'a>> {
        // Look for project/dependencies
        for child in root.children() {
            if child.has_tag_name("project") {
                for project_child in child.children() {
                    if project_child.has_tag_name("dependencies") {
                        return Some(project_child);
                    }
                }
            }
            // Also check if root is already project
            if child.has_tag_name("dependencies") {
                return Some(child);
            }
        }
        
        // If root is project, check direct children
        if root.has_tag_name("project") {
            for child in root.children() {
                if child.has_tag_name("dependencies") {
                    return Some(child);
                }
            }
        }
        
        None
    }
    
    fn create_dependency(
        &self,
        path: &Utf8Path,
        dependency_node: &Node,
    ) -> ParserResult<Option<Dependency>> {
        let mut group_id = String::new();
        let mut artifact_id = String::new();
        let mut version = String::new();
        let mut scope = String::new();
        let mut optional = String::new();
        let mut dependency_type = String::new();
        let mut classifier = String::new();
        
        // Extract dependency information from child nodes
        for child in dependency_node.children() {
            if let Some(text) = child.text() {
                match child.tag_name().name() {
                    "groupId" => group_id = text.trim().to_string(),
                    "artifactId" => artifact_id = text.trim().to_string(),
                    "version" => version = text.trim().to_string(),
                    "scope" => scope = text.trim().to_string(),
                    "optional" => optional = text.trim().to_string(),
                    "type" => dependency_type = text.trim().to_string(),
                    "classifier" => classifier = text.trim().to_string(),
                    _ => {}
                }
            }
        }
        
        // Skip dependencies with Maven variables that we can't resolve
        if group_id.contains("${") || artifact_id.contains("${") || version.contains("${") {
            debug!("Skipping dependency with unresolved variables: {}:{}:{}", group_id, artifact_id, version);
            return Ok(None);
        }
        
        if group_id.is_empty() || artifact_id.is_empty() || version.is_empty() {
            return Ok(None);
        }
        
        let name = format!("{}:{}", group_id, artifact_id);
        
        let mut meta = HashMap::new();
        meta.insert("group_id".to_string(), group_id);
        meta.insert("artifact_id".to_string(), artifact_id);
        
        if !scope.is_empty() {
            meta.insert("scope".to_string(), scope);
        }
        
        if !optional.is_empty() {
            meta.insert("optional".to_string(), optional);
        }
        
        if !dependency_type.is_empty() {
            meta.insert("type".to_string(), dependency_type);
        }
        
        if !classifier.is_empty() {
            meta.insert("classifier".to_string(), classifier);
        }
        
        let mut dependency = Dependency::new(name, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
}