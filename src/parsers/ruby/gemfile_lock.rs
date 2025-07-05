use async_trait::async_trait;
use camino::Utf8Path;
use regex::Regex;
use tracing::{debug, warn};

use crate::core::{
    parser::{Parser, ParserError, ParserResult},
    Dependency, DependencyCollection,
};

#[derive(Debug)]
pub struct GemfileLockParser {
    strip_bundled_with: Regex,
}

impl GemfileLockParser {
    pub fn new() -> Self {
        Self {
            strip_bundled_with: Regex::new(r"(?m)^BUNDLED WITH$\r?\n   \d+\.\d+\.\d+\r?\n?")
                .expect("Invalid regex pattern"),
        }
    }

    fn matches_filename(&self, filename: &str) -> bool {
        filename.starts_with("Gemfile") && filename.ends_with(".lock")
            || filename.starts_with("gems") && filename.ends_with(".lock")
    }

    async fn parse_gemfile_content(&self, content: &str, file_path: &Utf8Path) -> ParserResult<DependencyCollection> {
        debug!("Parsing Gemfile.lock content, {} bytes", content.len());

        // Remove BUNDLED WITH section that can interfere with parsing
        let cleaned_content = self.strip_bundled_with.replace_all(content, "");
        
        let mut dependencies = DependencyCollection::new();
        let parsed_data = self.parse_lockfile_format(&cleaned_content)?;

        // Use a map to deduplicate gems by name+version
        let mut gem_map = std::collections::HashMap::new();

        for spec in parsed_data.specs {
            let key = format!("{}:{}", spec.name, spec.version);
            
            // Only keep the first occurrence of each gem name+version combination
            // This effectively deduplicates platform-specific variants
            if !gem_map.contains_key(&key) {
                let dependency = Dependency::new(spec.name.clone(), spec.version.clone())
                    .with_location(file_path.to_path_buf())
                    .with_source("rubygems".to_string())
                    .add_metadata("platform".to_string(), spec.platform.clone())
                    .add_metadata("source".to_string(), spec.source.clone());

                gem_map.insert(key, dependency);
            }
        }

        // Add all unique dependencies to the collection
        for dependency in gem_map.into_values() {
            dependencies.add(dependency);
        }

        debug!("Parsed {} dependencies from {}", dependencies.len(), file_path);
        Ok(dependencies)
    }

    fn parse_lockfile_format(&self, content: &str) -> ParserResult<LockfileData> {
        let mut lockfile_data = LockfileData::new();
        let mut current_section = LockfileSection::None;
        let mut current_remote = String::new();
        let mut specs_indent = 0;

        for line in content.lines() {
            let trimmed = line.trim();
            
            // Skip empty lines and comments
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }

            // Detect section headers
            if let Some(section) = self.detect_section(trimmed) {
                current_section = section;
                continue;
            }

            match current_section {
                LockfileSection::Path => {
                    if line.starts_with("  remote:") {
                        current_remote = line.trim_start_matches("  remote:").trim().to_string();
                    } else if line.starts_with("  specs:") {
                        // Start of specs section
                        continue;
                    } else if line.starts_with("    ") {
                        // This is a gem specification
                        if specs_indent == 0 {
                            specs_indent = line.len() - line.trim_start().len();
                        }
                        
                        if line.len() - line.trim_start().len() == specs_indent {
                            if let Some(spec) = self.parse_gem_spec(line.trim(), &current_remote) {
                                lockfile_data.specs.push(spec);
                            }
                        }
                    }
                }
                LockfileSection::Gem => {
                    if line.starts_with("  remote:") {
                        current_remote = line.trim_start_matches("  remote:").trim().to_string();
                    } else if line.starts_with("  specs:") {
                        // Start of specs section
                        continue;
                    } else if line.starts_with("    ") {
                        // This is a gem specification
                        if specs_indent == 0 {
                            specs_indent = line.len() - line.trim_start().len();
                        }
                        
                        if line.len() - line.trim_start().len() == specs_indent {
                            if let Some(spec) = self.parse_gem_spec(line.trim(), &current_remote) {
                                lockfile_data.specs.push(spec);
                            }
                        }
                    }
                }
                LockfileSection::Platforms => {
                    if line.starts_with("  ") {
                        lockfile_data.platforms.push(line.trim().to_string());
                    }
                }
                LockfileSection::Dependencies => {
                    if line.starts_with("  ") {
                        lockfile_data.dependencies.push(line.trim().to_string());
                    }
                }
                LockfileSection::None => {
                    // Not in a recognized section, skip
                }
            }
        }

        Ok(lockfile_data)
    }

    fn detect_section(&self, line: &str) -> Option<LockfileSection> {
        match line {
            "PATH" => Some(LockfileSection::Path),
            "GEM" => Some(LockfileSection::Gem),
            "PLATFORMS" => Some(LockfileSection::Platforms),
            "DEPENDENCIES" => Some(LockfileSection::Dependencies),
            _ => None,
        }
    }

    fn parse_gem_spec(&self, line: &str, remote: &str) -> Option<GemSpec> {
        // Parse lines like: "net-hippie (0.2.7)"
        // or: "nokogiri (1.10.10-x86_64-darwin)"
        
        if let Some(captures) = self.extract_name_version(line) {
            let (name, version) = captures;
            Some(GemSpec {
                name,
                version,
                platform: "ruby".to_string(), // Default platform
                source: remote.to_string(),
                dependencies: Vec::new(),
            })
        } else {
            warn!("Failed to parse gem spec line: {}", line);
            None
        }
    }

    fn extract_name_version(&self, line: &str) -> Option<(String, String)> {
        // Handle various formats:
        // "gem_name (version)"
        // "gem_name (version-platform)"
        
        if let Some(paren_start) = line.find('(') {
            if let Some(paren_end) = line.rfind(')') {
                let name = line[..paren_start].trim().to_string();
                let version_part = line[paren_start + 1..paren_end].trim();
                
                // Extract version, potentially removing platform suffix
                // Only remove suffix if it looks like a platform (e.g., x86_64-darwin, java)
                // But keep version suffixes like beta-1, rc-2, etc.
                let version = if version_part.contains('-') {
                    // Common platform identifiers - more comprehensive list
                    let platform_indicators = [
                        "x86", "x64", "aarch64", "arm", "arm64", "i386", "i686",
                        "darwin", "linux", "windows", "mswin", "mingw", "cygwin",
                        "java", "jruby", "rbx", "ruby", "gnu", "musl", "universal"
                    ];
                    
                    // Check if any part after the first dash contains platform indicators
                    let parts: Vec<&str> = version_part.split('-').collect();
                    if parts.len() > 1 {
                        let potential_platform_parts = &parts[1..];
                        let has_platform = potential_platform_parts.iter()
                            .any(|part| platform_indicators.iter()
                                .any(|&indicator| part.to_lowercase().contains(indicator)));
                        
                        if has_platform {
                            // For platform-specific versions like "1.18.1-aarch64-linux-gnu", take the first part
                            parts[0].to_string()
                        } else {
                            // For version suffixes like "1.0.0-beta-1", keep the whole thing
                            version_part.to_string()
                        }
                    } else {
                        version_part.to_string()
                    }
                } else {
                    version_part.to_string()
                };
                
                return Some((name, version));
            }
        }
        
        None
    }
}

impl Default for GemfileLockParser {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl Parser for GemfileLockParser {
    fn can_parse(&self, path: &Utf8Path) -> bool {
        if let Some(filename) = path.file_name() {
            self.matches_filename(filename)
        } else {
            false
        }
    }

    async fn parse(&self, path: &Utf8Path) -> ParserResult<DependencyCollection> {
        let content = tokio::fs::read_to_string(path).await.map_err(ParserError::IoError)?;
        self.parse_gemfile_content(&content, path).await
    }

    fn name(&self) -> &'static str {
        "gemfile-lock"
    }

    fn file_patterns(&self) -> Vec<&'static str> {
        vec!["Gemfile*.lock", "gems*.lock"]
    }
}

#[derive(Debug, PartialEq)]
enum LockfileSection {
    None,
    Path,
    Gem,
    Platforms,
    Dependencies,
}

#[derive(Debug)]
struct LockfileData {
    specs: Vec<GemSpec>,
    platforms: Vec<String>,
    dependencies: Vec<String>,
}

impl LockfileData {
    fn new() -> Self {
        Self {
            specs: Vec::new(),
            platforms: Vec::new(),
            dependencies: Vec::new(),
        }
    }
}

#[derive(Debug, Clone)]
struct GemSpec {
    name: String,
    version: String,
    platform: String,
    source: String,
    #[allow(dead_code)]
    dependencies: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use camino::Utf8PathBuf;
    use tempfile::NamedTempFile;
    use std::io::Write;

    #[test]
    fn test_filename_matching() {
        let parser = GemfileLockParser::new();
        
        assert!(parser.matches_filename("Gemfile.lock"));
        assert!(parser.matches_filename("Gemfile.development.lock"));
        assert!(parser.matches_filename("gems.lock"));
        assert!(parser.matches_filename("gems.production.lock"));
        
        assert!(!parser.matches_filename("package.json"));
        assert!(!parser.matches_filename("Gemfile"));
        assert!(!parser.matches_filename("something.lock"));
    }

    #[test]
    fn test_can_parse() {
        let parser = GemfileLockParser::new();
        
        assert!(parser.can_parse(Utf8Path::new("/path/to/Gemfile.lock")));
        assert!(parser.can_parse(Utf8Path::new("/path/to/gems.lock")));
        assert!(!parser.can_parse(Utf8Path::new("/path/to/package.json")));
    }

    #[test]
    fn test_extract_name_version() {
        let parser = GemfileLockParser::new();
        
        assert_eq!(
            parser.extract_name_version("net-hippie (0.2.7)"),
            Some(("net-hippie".to_string(), "0.2.7".to_string()))
        );
        
        assert_eq!(
            parser.extract_name_version("nokogiri (1.10.10-x86_64-darwin)"),
            Some(("nokogiri".to_string(), "1.10.10".to_string()))
        );
        
        assert_eq!(
            parser.extract_name_version("some-gem (1.0.0-java)"),
            Some(("some-gem".to_string(), "1.0.0".to_string()))
        );
        
        // Version with dashes that aren't platform suffixes
        assert_eq!(
            parser.extract_name_version("pre-release (1.0.0-beta-1)"),
            Some(("pre-release".to_string(), "1.0.0-beta-1".to_string()))
        );
    }

    #[tokio::test]
    async fn test_parse_simple_gemfile_lock() {
        let content = r#"GEM
  remote: https://rubygems.org/
  specs:
    net-hippie (0.2.7)

PLATFORMS
  ruby

DEPENDENCIES
  net-hippie

BUNDLED WITH
   1.17.3
"#;

        let parser = GemfileLockParser::new();
        let mut temp_file = NamedTempFile::new().unwrap();
        write!(temp_file, "{}", content).unwrap();
        
        let path = Utf8PathBuf::try_from(temp_file.path().to_path_buf()).unwrap();
        let result = parser.parse_gemfile_content(content, &path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        let deps: Vec<_> = result.into_iter().collect();
        
        assert_eq!(deps[0].name, "net-hippie");
        assert_eq!(deps[0].version, "0.2.7");
        assert_eq!(deps[0].metadata.get("source"), Some(&"https://rubygems.org/".to_string()));
    }

    #[test]
    fn test_bundled_with_removal() {
        let parser = GemfileLockParser::new();
        let content = "Some content\nBUNDLED WITH\n   1.17.3\nMore content";
        let cleaned = parser.strip_bundled_with.replace_all(content, "");
        assert_eq!(cleaned, "Some content\nMore content");
    }

    #[test]
    fn test_section_detection() {
        let parser = GemfileLockParser::new();
        
        assert_eq!(parser.detect_section("GEM"), Some(LockfileSection::Gem));
        assert_eq!(parser.detect_section("PLATFORMS"), Some(LockfileSection::Platforms));
        assert_eq!(parser.detect_section("DEPENDENCIES"), Some(LockfileSection::Dependencies));
        assert_eq!(parser.detect_section("OTHER"), None);
    }

    #[test]
    fn test_parser_name_and_patterns() {
        let parser = GemfileLockParser::new();
        assert_eq!(parser.name(), "gemfile-lock");
        assert_eq!(parser.file_patterns(), vec!["Gemfile*.lock", "gems*.lock"]);
    }
}