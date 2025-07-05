use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use std::collections::HashMap;
use tracing::debug;

#[derive(Debug)]
pub struct TerraformLockParser;

impl TerraformLockParser {
    pub fn new() -> Self {
        Self
    }
    
    fn matches_filename(&self, filename: &str) -> bool {
        filename == ".terraform.lock.hcl"
    }
}

impl Default for TerraformLockParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for TerraformLockParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "terraform"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec![".terraform.lock.hcl"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing .terraform.lock.hcl at: {}", path);
        
        let content = tokio::fs::read_to_string(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let mut dependencies = DependencyCollection::new();
        
        // Parse HCL content line by line to extract provider blocks
        self.parse_hcl_content(&content, path, &mut dependencies)?;
        
        debug!("Found {} dependencies in .terraform.lock.hcl", dependencies.len());
        Ok(dependencies)
    }
}

impl TerraformLockParser {
    fn parse_hcl_content(
        &self,
        content: &str,
        path: &Utf8Path,
        dependencies: &mut DependencyCollection,
    ) -> ParserResult<()> {
        let mut lines = content.lines().peekable();
        
        while let Some(line) = lines.next() {
            let trimmed = line.trim();
            
            // Look for provider blocks
            if trimmed.starts_with("provider ") {
                if let Some(provider_name) = self.extract_provider_name(trimmed) {
                    // Parse the provider block
                    if let Some(dependency) = self.parse_provider_block(&provider_name, &mut lines, path)? {
                        dependencies.add(dependency);
                    }
                }
            }
        }
        
        Ok(())
    }
    
    fn extract_provider_name(&self, line: &str) -> Option<String> {
        // Extract provider name from line like: provider "registry.terraform.io/hashicorp/aws" {
        if let Some(start) = line.find('"') {
            if let Some(end) = line[start + 1..].find('"') {
                return Some(line[start + 1..start + 1 + end].to_string());
            }
        }
        None
    }
    
    fn parse_provider_block(
        &self,
        provider_name: &str,
        lines: &mut std::iter::Peekable<std::str::Lines>,
        path: &Utf8Path,
    ) -> ParserResult<Option<Dependency>> {
        let mut version = String::new();
        let mut constraints = String::new();
        let mut hashes = Vec::new();
        let mut brace_count = 1; // We've already seen the opening brace
        
        while let Some(line) = lines.next() {
            let trimmed = line.trim();
            
            // Track braces to know when the block ends
            brace_count += trimmed.chars().filter(|&c| c == '{').count();
            brace_count -= trimmed.chars().filter(|&c| c == '}').count();
            
            if brace_count == 0 {
                break; // End of provider block
            }
            
            // Parse version
            if trimmed.starts_with("version") {
                if let Some(extracted_version) = self.extract_quoted_value(trimmed) {
                    version = extracted_version;
                }
            }
            
            // Parse constraints
            if trimmed.starts_with("constraints") {
                if let Some(extracted_constraints) = self.extract_quoted_value(trimmed) {
                    constraints = extracted_constraints;
                }
            }
            
            // Parse hashes (multiline array)
            if trimmed.starts_with("hashes") && trimmed.contains('[') {
                // Start of hashes array
                if !trimmed.ends_with(']') {
                    // Multiline array, read until closing bracket
                    while let Some(hash_line) = lines.next() {
                        let hash_trimmed = hash_line.trim();
                        if hash_trimmed.contains(']') {
                            break;
                        }
                        // Extract quoted strings from hash lines
                        if hash_trimmed.starts_with('"') && hash_trimmed.ends_with(',') {
                            let hash_value = hash_trimmed.trim_end_matches(',').trim_matches('"');
                            if !hash_value.is_empty() {
                                hashes.push(hash_value.to_string());
                            }
                        } else if hash_trimmed.starts_with('"') && hash_trimmed.ends_with('"') {
                            let hash_value = hash_trimmed.trim_matches('"');
                            if !hash_value.is_empty() {
                                hashes.push(hash_value.to_string());
                            }
                        }
                    }
                }
            }
        }
        
        if version.is_empty() {
            return Ok(None);
        }
        
        let mut meta = HashMap::new();
        
        if !constraints.is_empty() {
            meta.insert("constraints".to_string(), constraints);
        }
        
        if !hashes.is_empty() {
            meta.insert("hashes".to_string(), hashes.join(","));
        }
        
        // Extract provider parts for metadata
        let parts: Vec<&str> = provider_name.split('/').collect();
        if parts.len() >= 3 {
            meta.insert("registry".to_string(), parts[0].to_string());
            meta.insert("namespace".to_string(), parts[1].to_string());
            meta.insert("name".to_string(), parts[2].to_string());
        }
        
        let mut dependency = Dependency::new(provider_name.to_string(), version);
        dependency.location = path.to_path_buf();
        dependency.metadata = meta;
        
        Ok(Some(dependency))
    }
    
    fn extract_quoted_value(&self, line: &str) -> Option<String> {
        // Extract value from lines like: version = "3.39.0"
        if let Some(equals_pos) = line.find('=') {
            let value_part = line[equals_pos + 1..].trim();
            if let Some(start) = value_part.find('"') {
                if let Some(end) = value_part[start + 1..].find('"') {
                    return Some(value_part[start + 1..start + 1 + end].to_string());
                }
            }
        }
        None
    }
}