use async_trait::async_trait;
use camino::{Utf8Path, Utf8PathBuf};
use std::collections::HashSet;
use thiserror::Error;

use super::DependencyCollection;

#[derive(Error, Debug)]
pub enum ParserError {
    #[error("File not found: {0}")]
    FileNotFound(Utf8PathBuf),
    #[error("Parse error: {0}")]
    ParseError(String),
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),
    #[error("YAML error: {0}")]
    YamlError(#[from] serde_yaml::Error),
    #[error("XML error: {0}")]
    XmlError(String),
    #[error("Unsupported file format: {0}")]
    UnsupportedFormat(String),
}

pub type ParserResult<T> = Result<T, ParserError>;

#[async_trait]
pub trait Parser: Send + Sync {
    /// Returns true if this parser can handle the given file
    fn can_parse(&self, path: &Utf8Path) -> bool;
    
    /// Parse the file and return dependencies
    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection>;
    
    /// Return the name of this parser
    fn name(&self) -> &'static str;
    
    /// Return file patterns this parser supports
    fn file_patterns(&self) -> Vec<&'static str>;
}

pub struct ParserRegistry {
    parsers: Vec<Box<dyn Parser>>,
}

impl ParserRegistry {
    pub fn new() -> Self {
        Self {
            parsers: Vec::new(),
        }
    }

    pub fn register<P: Parser + 'static>(&mut self, parser: P) {
        self.parsers.push(Box::new(parser));
    }

    pub fn find_parser(&self, path: &Utf8Path) -> Option<&dyn Parser> {
        self.parsers
            .iter()
            .find(|parser| parser.can_parse(path))
            .map(|parser| parser.as_ref())
    }

    pub async fn parse_file(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        match self.find_parser(path) {
            Some(parser) => parser.parse(path).await,
            None => Err(ParserError::UnsupportedFormat(path.to_string())),
        }
    }

    pub fn supported_files(&self) -> Vec<&'static str> {
        let mut patterns = HashSet::new();
        for parser in &self.parsers {
            for pattern in parser.file_patterns() {
                patterns.insert(pattern);
            }
        }
        let mut result: Vec<&'static str> = patterns.into_iter().collect();
        result.sort();
        result
    }

    pub fn parsers(&self) -> &[Box<dyn Parser>] {
        &self.parsers
    }
}

impl Default for ParserRegistry {
    fn default() -> Self {
        Self::new()
    }
}

/// Utility functions for parsers
pub mod utils {
    use super::*;
    use std::fs;

    pub async fn read_file_to_string(path: &Utf8Path) -> ParserResult<String> {
        if !path.exists() {
            return Err(ParserError::FileNotFound(path.to_path_buf()));
        }
        
        let content = tokio::fs::read_to_string(path).await?;
        Ok(content)
    }

    pub fn read_file_to_string_sync(path: &Utf8Path) -> ParserResult<String> {
        if !path.exists() {
            return Err(ParserError::FileNotFound(path.to_path_buf()));
        }
        
        let content = fs::read_to_string(path)?;
        Ok(content)
    }

    pub fn matches_pattern(filename: &str, pattern: &str) -> bool {
        match pattern {
            "*" => true,
            pattern if pattern.contains('*') => {
                let regex_pattern = pattern.replace("*", ".*");
                regex::Regex::new(&regex_pattern)
                    .map(|re| re.is_match(filename))
                    .unwrap_or(false)
            }
            pattern => filename == pattern,
        }
    }

    pub fn extract_filename(path: &Utf8Path) -> Option<&str> {
        path.file_name()
    }

    pub fn normalize_version(version: &str) -> String {
        // Remove common version prefixes
        let version = version.trim_start_matches("v");
        let version = version.trim_start_matches("=");
        let version = version.trim_start_matches("==");
        let version = version.trim_start_matches("~");
        let version = version.trim_start_matches("^");
        let version = version.trim_start_matches(">=");
        let version = version.trim_start_matches("<=");
        let version = version.trim_start_matches(">");
        let version = version.trim_start_matches("<");
        
        version.trim().to_string()
    }

    pub fn sanitize_package_name(name: &str) -> String {
        name.trim().to_lowercase()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::utils::*;

    #[test]
    fn test_matches_pattern() {
        assert!(matches_pattern("Gemfile.lock", "Gemfile.lock"));
        assert!(matches_pattern("package.json", "package.json"));
        assert!(matches_pattern("yarn.lock", "*.lock"));
        assert!(matches_pattern("Pipfile.lock", "Pipfile*"));
        assert!(!matches_pattern("random.txt", "*.lock"));
    }

    #[test]
    fn test_normalize_version() {
        assert_eq!(normalize_version("v1.0.0"), "1.0.0");
        assert_eq!(normalize_version("==1.0.0"), "1.0.0");
        assert_eq!(normalize_version("~1.0.0"), "1.0.0");
        assert_eq!(normalize_version("^1.0.0"), "1.0.0");
        assert_eq!(normalize_version(">=1.0.0"), "1.0.0");
        assert_eq!(normalize_version("1.0.0"), "1.0.0");
    }

    #[test]
    fn test_sanitize_package_name() {
        assert_eq!(sanitize_package_name("  Package-Name  "), "package-name");
        assert_eq!(sanitize_package_name("PACKAGE"), "package");
    }

    #[tokio::test]
    async fn test_parser_registry() {
        let registry = ParserRegistry::new();
        assert!(registry.parsers().is_empty());
        assert!(registry.supported_files().is_empty());
    }
}