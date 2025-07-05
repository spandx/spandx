use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;
use camino::Utf8PathBuf;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Dependency {
    pub name: String,
    pub version: String,
    pub licenses: Vec<String>,
    pub location: Utf8PathBuf,
    pub source: Option<String>,
    pub metadata: HashMap<String, String>,
}

impl Dependency {
    pub fn new(name: String, version: String) -> Self {
        Self {
            name,
            version,
            licenses: Vec::new(),
            location: Utf8PathBuf::new(),
            source: None,
            metadata: HashMap::new(),
        }
    }

    pub fn with_location(mut self, location: Utf8PathBuf) -> Self {
        self.location = location;
        self
    }

    pub fn with_source(mut self, source: String) -> Self {
        self.source = Some(source);
        self
    }

    pub fn with_license(mut self, license: String) -> Self {
        self.licenses.push(license);
        self
    }

    pub fn with_licenses(mut self, licenses: Vec<String>) -> Self {
        self.licenses = licenses;
        self
    }

    pub fn add_metadata(mut self, key: String, value: String) -> Self {
        self.metadata.insert(key, value);
        self
    }

    pub fn id(&self) -> String {
        format!("{}:{}", self.name, self.version)
    }

    pub fn has_licenses(&self) -> bool {
        !self.licenses.is_empty()
    }

    pub fn license_display(&self) -> String {
        if self.licenses.is_empty() {
            "".to_string()
        } else {
            self.licenses.join(" AND ")
        }
    }
}

impl fmt::Display for Dependency {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.name, self.version)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DependencyCollection {
    dependencies: Vec<Dependency>,
}

impl DependencyCollection {
    pub fn new() -> Self {
        Self {
            dependencies: Vec::new(),
        }
    }

    pub fn add(&mut self, dependency: Dependency) {
        self.dependencies.push(dependency);
    }

    pub fn extend(&mut self, other: DependencyCollection) {
        self.dependencies.extend(other.dependencies);
    }

    pub fn iter(&self) -> impl Iterator<Item = &Dependency> {
        self.dependencies.iter()
    }

    pub fn into_iter(self) -> impl Iterator<Item = Dependency> {
        self.dependencies.into_iter()
    }

    pub fn len(&self) -> usize {
        self.dependencies.len()
    }

    pub fn is_empty(&self) -> bool {
        self.dependencies.is_empty()
    }

    pub fn sort_by_name(&mut self) {
        self.dependencies.sort_by(|a, b| a.name.cmp(&b.name));
    }

    pub fn filter_by_location(&self, location: &Utf8PathBuf) -> DependencyCollection {
        let filtered: Vec<Dependency> = self
            .dependencies
            .iter()
            .filter(|dep| dep.location == *location)
            .cloned()
            .collect();
        
        DependencyCollection {
            dependencies: filtered,
        }
    }

    pub fn unique_licenses(&self) -> Vec<String> {
        let mut licenses = std::collections::HashSet::new();
        for dep in &self.dependencies {
            for license in &dep.licenses {
                licenses.insert(license.clone());
            }
        }
        let mut unique_licenses: Vec<String> = licenses.into_iter().collect();
        unique_licenses.sort();
        unique_licenses
    }
}

impl Default for DependencyCollection {
    fn default() -> Self {
        Self::new()
    }
}

impl From<Vec<Dependency>> for DependencyCollection {
    fn from(dependencies: Vec<Dependency>) -> Self {
        Self { dependencies }
    }
}

impl IntoIterator for DependencyCollection {
    type Item = Dependency;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.dependencies.into_iter()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dependency_creation() {
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string());
        assert_eq!(dep.name, "test");
        assert_eq!(dep.version, "1.0.0");
        assert!(dep.licenses.is_empty());
    }

    #[test]
    fn test_dependency_builder() {
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string())
            .with_license("MIT".to_string())
            .with_source("rubygems".to_string());
        
        assert_eq!(dep.licenses, vec!["MIT"]);
        assert_eq!(dep.source, Some("rubygems".to_string()));
    }

    #[test]
    fn test_dependency_id() {
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string());
        assert_eq!(dep.id(), "test:1.0.0");
    }

    #[test]
    fn test_dependency_collection() {
        let mut collection = DependencyCollection::new();
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string());
        
        collection.add(dep);
        assert_eq!(collection.len(), 1);
        assert!(!collection.is_empty());
    }
}