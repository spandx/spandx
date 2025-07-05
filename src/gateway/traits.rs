use crate::core::Dependency;
use anyhow::Result;
use async_trait::async_trait;
use std::fmt::Debug;

/// Gateway trait for fetching license information from package registries
#[async_trait]
pub trait Gateway: Send + Sync + Debug {
    /// Check if this gateway can handle the given dependency
    fn matches(&self, dependency: &Dependency) -> bool;
    
    /// Fetch license information for the given dependency
    async fn licenses_for(&self, dependency: &Dependency) -> Result<Vec<String>>;
    
    /// Get the name of this gateway (for logging/debugging)
    fn name(&self) -> &'static str;
    
    /// Get the base URL of the registry this gateway connects to
    fn base_url(&self) -> &str;
}

/// Registry information for package sources
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RegistryInfo {
    pub name: String,
    pub url: String,
    pub package_manager: String,
}

impl RegistryInfo {
    pub fn new(name: String, url: String, package_manager: String) -> Self {
        Self {
            name,
            url,
            package_manager,
        }
    }
}

/// Result type for gateway operations
pub type GatewayResult<T> = Result<T, GatewayError>;

/// Errors that can occur during gateway operations
#[derive(Debug, thiserror::Error)]
pub enum GatewayError {
    #[error("HTTP request failed: {0}")]
    Http(#[from] reqwest::Error),
    
    #[error("JSON parsing failed: {0}")]
    Json(#[from] serde_json::Error),
    
    #[error("XML parsing failed: {0}")]
    Xml(String),
    
    #[error("URL parsing failed: {0}")]
    Url(#[from] url::ParseError),
    
    #[error("Circuit breaker open for host: {host}")]
    CircuitBreakerOpen { host: String },
    
    #[error("Package not found: {name}@{version}")]
    PackageNotFound { name: String, version: String },
    
    #[error("Registry error: {message}")]
    Registry { message: String },
    
    #[error("Authentication failed for registry: {registry}")]
    Authentication { registry: String },
    
    #[error("Rate limit exceeded for registry: {registry}")]
    RateLimit { registry: String },
    
    #[error("Airgap mode enabled - network requests disabled")]
    AirgapMode,
    
    #[error("Operation timed out")]
    Timeout,
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

/// Metadata about a package from a registry
#[derive(Debug, Clone, PartialEq)]
pub struct PackageMetadata {
    pub name: String,
    pub version: String,
    pub licenses: Vec<String>,
    pub description: Option<String>,
    pub homepage: Option<String>,
    pub repository: Option<String>,
    pub authors: Vec<String>,
    pub dependencies: Vec<String>,
    pub registry: RegistryInfo,
}

impl PackageMetadata {
    pub fn new(name: String, version: String, registry: RegistryInfo) -> Self {
        Self {
            name,
            version,
            licenses: Vec::new(),
            description: None,
            homepage: None,
            repository: None,
            authors: Vec::new(),
            dependencies: Vec::new(),
            registry,
        }
    }
    
    pub fn with_licenses(mut self, licenses: Vec<String>) -> Self {
        self.licenses = licenses;
        self
    }
    
    pub fn with_description(mut self, description: Option<String>) -> Self {
        self.description = description;
        self
    }
    
    pub fn with_homepage(mut self, homepage: Option<String>) -> Self {
        self.homepage = homepage;
        self
    }
    
    pub fn with_repository(mut self, repository: Option<String>) -> Self {
        self.repository = repository;
        self
    }
    
    pub fn with_authors(mut self, authors: Vec<String>) -> Self {
        self.authors = authors;
        self
    }
    
    pub fn with_dependencies(mut self, dependencies: Vec<String>) -> Self {
        self.dependencies = dependencies;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_registry_info_creation() {
        let registry = RegistryInfo::new(
            "RubyGems".to_string(),
            "https://rubygems.org".to_string(),
            "rubygems".to_string(),
        );
        
        assert_eq!(registry.name, "RubyGems");
        assert_eq!(registry.url, "https://rubygems.org");
        assert_eq!(registry.package_manager, "rubygems");
    }

    #[test]
    fn test_package_metadata_builder() {
        let registry = RegistryInfo::new(
            "NPM".to_string(),
            "https://registry.npmjs.org".to_string(),
            "npm".to_string(),
        );
        
        let metadata = PackageMetadata::new(
            "lodash".to_string(),
            "4.17.21".to_string(),
            registry.clone(),
        )
        .with_licenses(vec!["MIT".to_string()])
        .with_description(Some("Lodash modular utilities.".to_string()))
        .with_homepage(Some("https://lodash.com/".to_string()));
        
        assert_eq!(metadata.name, "lodash");
        assert_eq!(metadata.version, "4.17.21");
        assert_eq!(metadata.licenses, vec!["MIT"]);
        assert_eq!(metadata.description, Some("Lodash modular utilities.".to_string()));
        assert_eq!(metadata.registry, registry);
    }

    #[test]
    fn test_gateway_error_display() {
        let error = GatewayError::PackageNotFound {
            name: "nonexistent".to_string(),
            version: "1.0.0".to_string(),
        };
        
        assert_eq!(
            error.to_string(),
            "Package not found: nonexistent@1.0.0"
        );
        
        let error = GatewayError::CircuitBreakerOpen {
            host: "api.example.com".to_string(),
        };
        
        assert_eq!(
            error.to_string(),
            "Circuit breaker open for host: api.example.com"
        );
    }
}