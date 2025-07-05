use crate::core::Dependency;
use crate::gateway::traits::{Gateway, GatewayError, GatewayResult};
use crate::gateway::HttpClient;
use std::sync::Arc;
use tracing::{debug, warn};

/// Registry for managing and discovering package registry gateways
#[derive(Debug)]
pub struct GatewayRegistry {
    gateways: Vec<Box<dyn Gateway>>,
    http_client: Arc<HttpClient>,
}

impl GatewayRegistry {
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            gateways: Vec::new(),
            http_client,
        }
    }

    /// Register a new gateway
    pub fn register<G>(&mut self, gateway: G)
    where
        G: Gateway + 'static,
    {
        debug!("Registering gateway: {}", gateway.name());
        self.gateways.push(Box::new(gateway));
    }

    /// Find the first gateway that matches the given dependency
    pub fn find_gateway(&self, dependency: &Dependency) -> Option<&dyn Gateway> {
        for gateway in &self.gateways {
            if gateway.matches(dependency) {
                debug!(
                    "Found matching gateway '{}' for dependency {}@{}",
                    gateway.name(),
                    dependency.name,
                    dependency.version
                );
                return Some(gateway.as_ref());
            }
        }
        
        debug!(
            "No gateway found for dependency {}@{} (source: {:?})",
            dependency.name, dependency.version, dependency.source
        );
        None
    }

    /// Get license information for a dependency using the appropriate gateway
    pub async fn get_licenses(&self, dependency: &Dependency) -> GatewayResult<Vec<String>> {
        if let Some(gateway) = self.find_gateway(dependency) {
            debug!(
                "Fetching licenses for {}@{} using gateway '{}'",
                dependency.name, dependency.version, gateway.name()
            );
            
            match gateway.licenses_for(dependency).await {
                Ok(licenses) => {
                    debug!(
                        "Found {} licenses for {}@{}: {:?}",
                        licenses.len(), dependency.name, dependency.version, licenses
                    );
                    Ok(licenses)
                }
                Err(e) => {
                    warn!(
                        "Failed to get licenses for {}@{} from gateway '{}': {}",
                        dependency.name, dependency.version, gateway.name(), e
                    );
                    Err(GatewayError::Registry {
                        message: format!("Gateway '{}' failed: {}", gateway.name(), e),
                    })
                }
            }
        } else {
            Ok(Vec::new()) // Return empty list if no gateway found
        }
    }

    /// Get all registered gateways
    pub fn gateways(&self) -> &[Box<dyn Gateway>] {
        &self.gateways
    }

    /// Get the number of registered gateways
    pub fn len(&self) -> usize {
        self.gateways.len()
    }

    /// Check if there are any registered gateways
    pub fn is_empty(&self) -> bool {
        self.gateways.is_empty()
    }

    /// Get a reference to the HTTP client
    pub fn http_client(&self) -> Arc<HttpClient> {
        Arc::clone(&self.http_client)
    }

    /// Get license information for multiple dependencies concurrently
    pub async fn get_licenses_batch(
        &self,
        dependencies: &[Dependency],
    ) -> Vec<(Dependency, GatewayResult<Vec<String>>)> {
        let futures = dependencies.iter().map(|dep| async {
            let result = self.get_licenses(dep).await;
            (dep.clone(), result)
        });

        futures::future::join_all(futures).await
    }

    /// List all supported package managers from registered gateways
    pub fn supported_package_managers(&self) -> Vec<String> {
        // This would typically be implemented by asking each gateway
        // what package managers it supports. For now, return common ones.
        vec![
            "rubygems".to_string(),
            "npm".to_string(),
            "yarn".to_string(),
            "pypi".to_string(),
            "nuget".to_string(),
            "maven".to_string(),
            "packagist".to_string(),
        ]
    }
}

impl Default for GatewayRegistry {
    fn default() -> Self {
        Self::new(Arc::new(HttpClient::new()))
    }
}

/// Builder for constructing a gateway registry with common gateways
pub struct GatewayRegistryBuilder {
    registry: GatewayRegistry,
}

impl GatewayRegistryBuilder {
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            registry: GatewayRegistry::new(http_client),
        }
    }

    pub fn with_rubygems(self) -> Self {
        // Would register RubyGems gateway here
        // self.registry.register(RubyGemsGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_npm(self) -> Self {
        // Would register NPM gateway here
        // self.registry.register(NpmGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_pypi(self) -> Self {
        // Would register PyPI gateway here
        // self.registry.register(PypiGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_nuget(self) -> Self {
        // Would register NuGet gateway here
        // self.registry.register(NugetGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_maven(self) -> Self {
        // Would register Maven gateway here
        // self.registry.register(MavenGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_packagist(self) -> Self {
        // Would register Packagist gateway here
        // self.registry.register(PackagistGateway::new(self.registry.http_client()));
        self
    }

    pub fn with_all_default_gateways(self) -> Self {
        self.with_rubygems()
            .with_npm()
            .with_pypi()
            .with_nuget()
            .with_maven()
            .with_packagist()
    }

    pub fn build(self) -> GatewayRegistry {
        self.registry
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::PackageManager;
    use async_trait::async_trait;

    // Mock gateway for testing
    #[derive(Debug)]
    struct MockGateway {
        name: &'static str,
        package_manager: PackageManager,
        licenses: Vec<String>,
    }

    impl MockGateway {
        fn new(name: &'static str, package_manager: PackageManager, licenses: Vec<String>) -> Self {
            Self {
                name,
                package_manager,
                licenses,
            }
        }
    }

    #[async_trait]
    impl Gateway for MockGateway {
        fn matches(&self, dependency: &Dependency) -> bool {
            if let Some(source) = &dependency.source {
                PackageManager::from_source(source) == self.package_manager
            } else {
                false
            }
        }

        async fn licenses_for(&self, _dependency: &Dependency) -> anyhow::Result<Vec<String>> {
            Ok(self.licenses.clone())
        }

        fn name(&self) -> &'static str {
            self.name
        }

        fn base_url(&self) -> &str {
            "https://mock.example.com"
        }
    }

    #[tokio::test]
    async fn test_gateway_registry_registration() {
        let http_client = Arc::new(HttpClient::new());
        let mut registry = GatewayRegistry::new(http_client);
        
        let gateway = MockGateway::new("MockRubyGems", PackageManager::RubyGems, vec!["MIT".to_string()]);
        registry.register(gateway);
        
        assert_eq!(registry.len(), 1);
        assert!(!registry.is_empty());
    }

    #[tokio::test]
    async fn test_gateway_matching() {
        let http_client = Arc::new(HttpClient::new());
        let mut registry = GatewayRegistry::new(http_client);
        
        let rubygems_gateway = MockGateway::new(
            "MockRubyGems",
            PackageManager::RubyGems,
            vec!["MIT".to_string()],
        );
        let npm_gateway = MockGateway::new(
            "MockNPM",
            PackageManager::Npm,
            vec!["Apache-2.0".to_string()],
        );
        
        registry.register(rubygems_gateway);
        registry.register(npm_gateway);
        
        let ruby_dep = Dependency::new("rails".to_string(), "7.0.0".to_string())
            .with_source("rubygems".to_string());
        
        let npm_dep = Dependency::new("lodash".to_string(), "4.17.21".to_string())
            .with_source("npm".to_string());
        
        let ruby_gateway = registry.find_gateway(&ruby_dep);
        assert!(ruby_gateway.is_some());
        assert_eq!(ruby_gateway.unwrap().name(), "MockRubyGems");
        
        let npm_gateway = registry.find_gateway(&npm_dep);
        assert!(npm_gateway.is_some());
        assert_eq!(npm_gateway.unwrap().name(), "MockNPM");
    }

    #[tokio::test]
    async fn test_get_licenses() {
        let http_client = Arc::new(HttpClient::new());
        let mut registry = GatewayRegistry::new(http_client);
        
        let gateway = MockGateway::new(
            "MockRubyGems",
            PackageManager::RubyGems,
            vec!["MIT".to_string(), "Apache-2.0".to_string()],
        );
        registry.register(gateway);
        
        let dependency = Dependency::new("rails".to_string(), "7.0.0".to_string())
            .with_source("rubygems".to_string());
        
        let licenses = registry.get_licenses(&dependency).await.unwrap();
        assert_eq!(licenses, vec!["MIT", "Apache-2.0"]);
    }

    #[tokio::test]
    async fn test_no_matching_gateway() {
        let http_client = Arc::new(HttpClient::new());
        let registry = GatewayRegistry::new(http_client);
        
        let dependency = Dependency::new("unknown".to_string(), "1.0.0".to_string())
            .with_source("unknown_pm".to_string());
        
        let licenses = registry.get_licenses(&dependency).await.unwrap();
        assert!(licenses.is_empty());
    }

    #[test]
    fn test_builder_pattern() {
        let http_client = Arc::new(HttpClient::new());
        let registry = GatewayRegistryBuilder::new(http_client)
            .with_rubygems()
            .with_npm()
            .build();
        
        // Registry is built but no actual gateways are registered in this test
        // because the actual gateway implementations are not available
        assert_eq!(registry.len(), 0);
    }
}