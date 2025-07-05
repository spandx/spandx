use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};
use async_trait::async_trait;
use camino::Utf8Path;
use regex::Regex;
use std::collections::HashMap;
use tokio::io::{AsyncBufReadExt, BufReader};
use tracing::debug;

#[derive(Debug)]
pub struct YarnParser {
    start_regex: Regex,
    inject_colon: Regex,
}

impl YarnParser {
    pub fn new() -> Self {
        Self {
            start_regex: Regex::new(r#"^"?(?P<name>(?:@|[\w\-\./])+)@"#).unwrap(),
            inject_colon: Regex::new(r#"(\w|")\s(\w|")"#).unwrap(),
        }
    }
}

impl Default for YarnParser {
    fn default() -> Self {
        Self::new()
    }
}

impl YarnParser {
    fn matches_filename(&self, filename: &str) -> bool {
        filename == "yarn.lock"
    }
}

#[async_trait]
impl Parser for YarnParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        path.file_name()
            .map(|name| self.matches_filename(name))
            .unwrap_or(false)
    }
    
    fn name(&self) -> &'static str {
        "yarn"
    }
    
    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["yarn.lock"]
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing yarn.lock at: {}", path);
        
        let file = tokio::fs::File::open(path)
            .await
            .map_err(|_| ParserError::FileNotFound(path.to_path_buf()))?;
        
        let reader = BufReader::new(file);
        let mut lines = reader.lines();
        let mut dependencies = DependencyCollection::new();
        
        while let Some(line) = lines.next_line().await.map_err(ParserError::IoError)? {
            if let Some(dependency) = self.parse_dependency_from_line(&line, &mut lines, path).await? {
                dependencies.add(dependency);
            }
        }
        
        debug!("Found {} dependencies in yarn.lock", dependencies.len());
        Ok(dependencies)
    }
}

impl YarnParser {
    async fn parse_dependency_from_line(
        &self,
        header: &str,
        lines: &mut tokio::io::Lines<BufReader<tokio::fs::File>>,
        path: &Utf8Path,
    ) -> ParserResult<Option<Dependency>> {
        let captures = match self.start_regex.captures(header) {
            Some(caps) => caps,
            None => return Ok(None),
        };
        
        let name = captures
            .name("name")
            .map(|m| m.as_str().trim_matches('"'))
            .unwrap_or("")
            .to_string();
        
        if name.is_empty() {
            return Ok(None);
        }
        
        let dependency_lines = self.read_dependency_lines(lines).await?;
        let metadata = self.parse_yaml_like_content(&name, &dependency_lines)?;
        
        let version = metadata
            .get("version")
            .cloned()
            .unwrap_or_default();
        
        if version.is_empty() {
            return Ok(None);
        }
        
        let mut dependency = Dependency::new(name, version);
        dependency.location = path.to_path_buf();
        dependency.metadata = metadata;
        
        Ok(Some(dependency))
    }
    
    async fn read_dependency_lines(
        &self,
        lines: &mut tokio::io::Lines<BufReader<tokio::fs::File>>,
    ) -> ParserResult<Vec<String>> {
        let mut dependency_lines = Vec::new();
        
        while let Some(line) = lines.next_line().await.map_err(ParserError::IoError)? {
            let trimmed = line.trim();
            
            if trimmed.is_empty() {
                break;
            }
            
            dependency_lines.push(trimmed.to_string());
        }
        
        Ok(dependency_lines)
    }
    
    fn parse_yaml_like_content(
        &self,
        name: &str,
        lines: &[String],
    ) -> ParserResult<HashMap<String, String>> {
        let mut metadata = HashMap::new();
        metadata.insert("name".to_string(), name.to_string());
        
        for line in lines {
            let yaml_line = self.inject_colon.replace_all(line, "$1: $2");
            
            if let Some((key, value)) = yaml_line.split_once(':') {
                let key = key.trim().to_string();
                let value = value.trim().trim_matches('"').to_string();
                
                if !key.is_empty() && !value.is_empty() {
                    metadata.insert(key, value);
                }
            }
        }
        
        Ok(metadata)
    }
}