use crate::core::{Dependency, PackageManager};
use crate::gateway::traits::{Gateway, GatewayError, GatewayResult, PackageMetadata, RegistryInfo};
use crate::gateway::HttpClient;
use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{debug, warn};

/// Gateway for fetching package information from NPM registry
#[derive(Debug)]
pub struct NpmGateway {
    http_client: Arc<HttpClient>,
    base_url: String,
}

impl NpmGateway {
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            http_client,
            base_url: "https://registry.npmjs.org".to_string(),
        }
    }

    pub fn with_custom_registry(http_client: Arc<HttpClient>, base_url: String) -> Self {
        Self {
            http_client,
            base_url,
        }
    }

    async fn get_package_info(&self, name: &str, version: &str) -> GatewayResult<NpmPackageResponse> {
        let encoded_name = urlencoding::encode(name);
        let url = format!("{}/{}/{}", self.base_url, encoded_name, version);
        
        debug!("Fetching NPM package info from: {}", url);
        
        match self.http_client.get_json::<NpmPackageResponse>(&url).await {
            Ok(response) => Ok(response),
            Err(e) => {
                warn!("Failed to fetch NPM info for {}@{}: {}", name, version, e);
                Err(GatewayError::PackageNotFound {
                    name: name.to_string(),
                    version: version.to_string(),
                })
            }
        }
    }

    #[allow(dead_code)]
    async fn get_package_latest(&self, name: &str) -> GatewayResult<NpmRegistryResponse> {
        let encoded_name = urlencoding::encode(name);
        let url = format!("{}/{}", self.base_url, encoded_name);
        
        debug!("Fetching NPM package registry info from: {}", url);
        
        match self.http_client.get_json::<NpmRegistryResponse>(&url).await {
            Ok(response) => Ok(response),
            Err(e) => {
                warn!("Failed to fetch NPM registry info for {}: {}", name, e);
                Err(GatewayError::PackageNotFound {
                    name: name.to_string(),
                    version: "latest".to_string(),
                })
            }
        }
    }

    fn extract_licenses(&self, package_info: &NpmPackageResponse) -> Vec<String> {
        let mut licenses = Vec::new();
        
        // Handle different license field formats
        match &package_info.license {
            Some(serde_json::Value::String(license)) => {
                if !license.trim().is_empty() {
                    licenses.push(license.clone());
                }
            }
            Some(serde_json::Value::Object(license_obj)) => {
                if let Some(serde_json::Value::String(license_type)) = license_obj.get("type") {
                    if !license_type.trim().is_empty() {
                        licenses.push(license_type.clone());
                    }
                }
            }
            Some(serde_json::Value::Array(license_array)) => {
                for license_item in license_array {
                    match license_item {
                        serde_json::Value::String(license) => {
                            if !license.trim().is_empty() {
                                licenses.push(license.clone());
                            }
                        }
                        serde_json::Value::Object(license_obj) => {
                            if let Some(serde_json::Value::String(license_type)) = license_obj.get("type") {
                                if !license_type.trim().is_empty() {
                                    licenses.push(license_type.clone());
                                }
                            }
                        }
                        _ => {}
                    }
                }
            }
            _ => {}
        }
        
        // Also check licenses field (plural)
        if let Some(package_licenses) = &package_info.licenses {
            for license_item in package_licenses {
                match license_item {
                    serde_json::Value::String(license) => {
                        if !license.trim().is_empty() && !licenses.contains(license) {
                            licenses.push(license.clone());
                        }
                    }
                    serde_json::Value::Object(license_obj) => {
                        if let Some(serde_json::Value::String(license_type)) = license_obj.get("type") {
                            if !license_type.trim().is_empty() && !licenses.contains(license_type) {
                                licenses.push(license_type.clone());
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
        
        // Remove duplicates and sort
        licenses.sort();
        licenses.dedup();
        
        debug!("Extracted licenses for {}: {:?}", package_info.name, licenses);
        licenses
    }
}

#[async_trait]
impl Gateway for NpmGateway {
    fn matches(&self, dependency: &Dependency) -> bool {
        if let Some(source) = &dependency.source {
            let pm = PackageManager::from_source(source);
            pm.is_javascript()
        } else {
            false
        }
    }

    async fn licenses_for(&self, dependency: &Dependency) -> Result<Vec<String>> {
        let package_info = self.get_package_info(&dependency.name, &dependency.version).await?;
        Ok(self.extract_licenses(&package_info))
    }

    fn name(&self) -> &'static str {
        "NPM"
    }

    fn base_url(&self) -> &str {
        &self.base_url
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct NpmPackageResponse {
    name: String,
    version: String,
    description: Option<String>,
    license: Option<serde_json::Value>,
    licenses: Option<Vec<serde_json::Value>>,
    homepage: Option<String>,
    repository: Option<serde_json::Value>,
    author: Option<serde_json::Value>,
    contributors: Option<Vec<serde_json::Value>>,
    dependencies: Option<std::collections::HashMap<String, String>>,
    #[serde(rename = "devDependencies")]
    dev_dependencies: Option<std::collections::HashMap<String, String>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct NpmRegistryResponse {
    name: String,
    description: Option<String>,
    #[serde(rename = "dist-tags")]
    dist_tags: Option<std::collections::HashMap<String, String>>,
    versions: std::collections::HashMap<String, NpmPackageResponse>,
    license: Option<serde_json::Value>,
    homepage: Option<String>,
    repository: Option<serde_json::Value>,
}

impl From<NpmPackageResponse> for PackageMetadata {
    fn from(response: NpmPackageResponse) -> Self {
        let registry = RegistryInfo::new(
            "NPM".to_string(),
            "https://registry.npmjs.org".to_string(),
            "npm".to_string(),
        );

        let repository = match response.repository {
            Some(serde_json::Value::String(repo)) => Some(repo),
            Some(serde_json::Value::Object(repo_obj)) => {
                repo_obj.get("url").and_then(|v| v.as_str()).map(|s| s.to_string())
            }
            _ => None,
        };

        let mut authors = Vec::new();
        if let Some(author) = response.author {
            match author {
                serde_json::Value::String(author_name) => authors.push(author_name),
                serde_json::Value::Object(author_obj) => {
                    if let Some(serde_json::Value::String(name)) = author_obj.get("name") {
                        authors.push(name.clone());
                    }
                }
                _ => {}
            }
        }

        if let Some(contributors) = response.contributors {
            for contributor in contributors {
                match contributor {
                    serde_json::Value::String(contributor_name) => {
                        if !authors.contains(&contributor_name) {
                            authors.push(contributor_name);
                        }
                    }
                    serde_json::Value::Object(contributor_obj) => {
                        if let Some(serde_json::Value::String(name)) = contributor_obj.get("name") {
                            if !authors.contains(name) {
                                authors.push(name.clone());
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        PackageMetadata::new(response.name, response.version, registry)
            .with_description(response.description)
            .with_homepage(response.homepage)
            .with_repository(repository)
            .with_authors(authors)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::{Mock, MockServer, ResponseTemplate};
    use wiremock::matchers::{method, path};

    #[tokio::test]
    async fn test_npm_gateway_matches() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = NpmGateway::new(http_client);

        let npm_dep = Dependency::new("lodash".to_string(), "4.17.21".to_string())
            .with_source("npm".to_string());

        let yarn_dep = Dependency::new("react".to_string(), "18.0.0".to_string())
            .with_source("yarn".to_string());

        let ruby_dep = Dependency::new("rails".to_string(), "7.0.0".to_string())
            .with_source("rubygems".to_string());

        assert!(gateway.matches(&npm_dep));
        assert!(gateway.matches(&yarn_dep));
        assert!(!gateway.matches(&ruby_dep));
    }

    #[tokio::test]
    async fn test_get_package_info() {
        let mock_server = MockServer::start().await;
        let http_client = Arc::new(HttpClient::new());
        let gateway = NpmGateway::with_custom_registry(
            http_client,
            mock_server.uri(),
        );

        let response_body = serde_json::json!({
            "name": "lodash",
            "version": "4.17.21",
            "description": "Lodash modular utilities.",
            "license": "MIT",
            "homepage": "https://lodash.com/",
            "repository": {
                "type": "git",
                "url": "git+https://github.com/lodash/lodash.git"
            }
        });

        Mock::given(method("GET"))
            .and(path("/lodash/4.17.21"))
            .respond_with(ResponseTemplate::new(200).set_body_json(&response_body))
            .mount(&mock_server)
            .await;

        let dependency = Dependency::new("lodash".to_string(), "4.17.21".to_string())
            .with_source("npm".to_string());

        let licenses = gateway.licenses_for(&dependency).await.unwrap();
        assert_eq!(licenses, vec!["MIT"]);
    }

    #[tokio::test]
    async fn test_extract_licenses_different_formats() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = NpmGateway::new(http_client);

        // Test string license
        let response1 = NpmPackageResponse {
            name: "test-pkg1".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            license: Some(serde_json::Value::String("MIT".to_string())),
            licenses: None,
            homepage: None,
            repository: None,
            author: None,
            contributors: None,
            dependencies: None,
            dev_dependencies: None,
        };
        let licenses1 = gateway.extract_licenses(&response1);
        assert_eq!(licenses1, vec!["MIT"]);

        // Test object license
        let response2 = NpmPackageResponse {
            name: "test-pkg2".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            license: Some(serde_json::json!({"type": "Apache-2.0"})),
            licenses: None,
            homepage: None,
            repository: None,
            author: None,
            contributors: None,
            dependencies: None,
            dev_dependencies: None,
        };
        let licenses2 = gateway.extract_licenses(&response2);
        assert_eq!(licenses2, vec!["Apache-2.0"]);

        // Test array of licenses
        let response3 = NpmPackageResponse {
            name: "test-pkg3".to_string(),
            version: "1.0.0".to_string(),
            description: None,
            license: None,
            licenses: Some(vec![
                serde_json::Value::String("MIT".to_string()),
                serde_json::json!({"type": "BSD-3-Clause"}),
            ]),
            homepage: None,
            repository: None,
            author: None,
            contributors: None,
            dependencies: None,
            dev_dependencies: None,
        };
        let licenses3 = gateway.extract_licenses(&response3);
        assert_eq!(licenses3, vec!["BSD-3-Clause", "MIT"]);
    }

    #[tokio::test]
    async fn test_scoped_package_url_encoding() {
        let mock_server = MockServer::start().await;
        let http_client = Arc::new(HttpClient::new());
        let gateway = NpmGateway::with_custom_registry(
            http_client,
            mock_server.uri(),
        );

        let response_body = serde_json::json!({
            "name": "@types/node",
            "version": "18.0.0",
            "license": "MIT"
        });

        Mock::given(method("GET"))
            .and(path("/@types%2Fnode/18.0.0"))
            .respond_with(ResponseTemplate::new(200).set_body_json(&response_body))
            .mount(&mock_server)
            .await;

        let dependency = Dependency::new("@types/node".to_string(), "18.0.0".to_string())
            .with_source("npm".to_string());

        let licenses = gateway.licenses_for(&dependency).await.unwrap();
        assert_eq!(licenses, vec!["MIT"]);
    }
}