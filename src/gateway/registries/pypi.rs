use crate::core::{Dependency, PackageManager};
use crate::gateway::traits::{Gateway, GatewayError, GatewayResult, PackageMetadata, RegistryInfo};
use crate::gateway::HttpClient;
use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{debug, warn};

/// Gateway for fetching package information from PyPI
#[derive(Debug)]
pub struct PypiGateway {
    http_client: Arc<HttpClient>,
    base_url: String,
}

impl PypiGateway {
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            http_client,
            base_url: "https://pypi.org".to_string(),
        }
    }

    pub fn with_custom_index(http_client: Arc<HttpClient>, base_url: String) -> Self {
        Self {
            http_client,
            base_url,
        }
    }

    async fn get_package_info(&self, name: &str, version: &str) -> GatewayResult<PypiResponse> {
        let url = format!("{}/pypi/{}/{}/json", self.base_url, name, version);
        
        debug!("Fetching PyPI package info from: {}", url);
        
        match self.http_client.get_json::<PypiResponse>(&url).await {
            Ok(response) => Ok(response),
            Err(e) => {
                warn!("Failed to fetch PyPI info for {}@{}: {}", name, version, e);
                Err(GatewayError::PackageNotFound {
                    name: name.to_string(),
                    version: version.to_string(),
                })
            }
        }
    }

    fn extract_licenses(&self, package_info: &PypiInfo) -> Vec<String> {
        let mut licenses = Vec::new();
        
        // Extract from license field
        if let Some(license) = &package_info.license {
            if !license.trim().is_empty() && license != "UNKNOWN" {
                licenses.push(license.clone());
            }
        }
        
        // Extract from classifiers
        if let Some(classifiers) = &package_info.classifiers {
            for classifier in classifiers {
                if classifier.starts_with("License ::") {
                    // Extract license name from classifier
                    // e.g., "License :: OSI Approved :: MIT License" -> "MIT"
                    if let Some(license_part) = classifier.split(" :: ").last() {
                        let license_name = license_part
                            .replace(" License", "")
                            .replace("GNU ", "")
                            .replace("Library or ", "")
                            .trim()
                            .to_string();
                        
                        if !license_name.is_empty() 
                            && license_name != "OSI Approved"
                            && !licenses.contains(&license_name) {
                            licenses.push(license_name);
                        }
                    }
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
impl Gateway for PypiGateway {
    fn matches(&self, dependency: &Dependency) -> bool {
        if let Some(source) = &dependency.source {
            let pm = PackageManager::from_source(source);
            pm.is_python()
        } else {
            false
        }
    }

    async fn licenses_for(&self, dependency: &Dependency) -> Result<Vec<String>> {
        let response = self.get_package_info(&dependency.name, &dependency.version).await?;
        Ok(self.extract_licenses(&response.info))
    }

    fn name(&self) -> &'static str {
        "PyPI"
    }

    fn base_url(&self) -> &str {
        &self.base_url
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct PypiResponse {
    info: PypiInfo,
    urls: Vec<PypiUrl>,
}

#[derive(Debug, Serialize, Deserialize)]
struct PypiInfo {
    name: String,
    version: String,
    summary: Option<String>,
    description: Option<String>,
    license: Option<String>,
    home_page: Option<String>,
    project_url: Option<String>,
    project_urls: Option<std::collections::HashMap<String, String>>,
    author: Option<String>,
    author_email: Option<String>,
    maintainer: Option<String>,
    maintainer_email: Option<String>,
    classifiers: Option<Vec<String>>,
    keywords: Option<String>,
    requires_dist: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct PypiUrl {
    filename: String,
    url: String,
    #[serde(rename = "packagetype")]
    package_type: String,
}

impl From<PypiResponse> for PackageMetadata {
    fn from(response: PypiResponse) -> Self {
        let registry = RegistryInfo::new(
            "PyPI".to_string(),
            "https://pypi.org".to_string(),
            "python".to_string(),
        );

        let mut authors = Vec::new();
        if let Some(author) = response.info.author {
            if !author.trim().is_empty() {
                authors.push(author);
            }
        }
        if let Some(maintainer) = response.info.maintainer {
            if !maintainer.trim().is_empty() && !authors.contains(&maintainer) {
                authors.push(maintainer);
            }
        }

        // Extract repository URL from project_urls
        let repository = response.info.project_urls
            .as_ref()
            .and_then(|urls| {
                urls.get("Source")
                    .or_else(|| urls.get("Repository"))
                    .or_else(|| urls.get("Homepage"))
                    .cloned()
            })
            .or_else(|| response.info.home_page.clone());

        let dependencies = response.info.requires_dist.unwrap_or_default();

        PackageMetadata::new(response.info.name, response.info.version, registry)
            .with_description(response.info.summary)
            .with_homepage(response.info.home_page)
            .with_repository(repository)
            .with_authors(authors)
            .with_dependencies(dependencies)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::{Mock, MockServer, ResponseTemplate};
    use wiremock::matchers::{method, path};

    #[tokio::test]
    async fn test_pypi_gateway_matches() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = PypiGateway::new(http_client);

        let python_dep = Dependency::new("requests".to_string(), "2.28.0".to_string())
            .with_source("python".to_string());

        let npm_dep = Dependency::new("lodash".to_string(), "4.17.21".to_string())
            .with_source("npm".to_string());

        assert!(gateway.matches(&python_dep));
        assert!(!gateway.matches(&npm_dep));
    }

    #[tokio::test]
    async fn test_get_package_info() {
        let mock_server = MockServer::start().await;
        let http_client = Arc::new(HttpClient::new());
        let gateway = PypiGateway::with_custom_index(
            http_client,
            mock_server.uri(),
        );

        let response_body = serde_json::json!({
            "info": {
                "name": "requests",
                "version": "2.28.0",
                "summary": "Python HTTP for Humans.",
                "license": "Apache 2.0",
                "home_page": "https://requests.readthedocs.io",
                "author": "Kenneth Reitz",
                "classifiers": [
                    "License :: OSI Approved :: Apache Software License"
                ]
            },
            "urls": []
        });

        Mock::given(method("GET"))
            .and(path("/pypi/requests/2.28.0/json"))
            .respond_with(ResponseTemplate::new(200).set_body_json(&response_body))
            .mount(&mock_server)
            .await;

        let dependency = Dependency::new("requests".to_string(), "2.28.0".to_string())
            .with_source("python".to_string());

        let licenses = gateway.licenses_for(&dependency).await.unwrap();
        assert!(licenses.contains(&"Apache 2.0".to_string()) || licenses.contains(&"Apache Software".to_string()));
    }

    #[tokio::test]
    async fn test_extract_licenses_from_classifiers() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = PypiGateway::new(http_client);

        let package_info = PypiInfo {
            name: "test-package".to_string(),
            version: "1.0.0".to_string(),
            summary: None,
            description: None,
            license: None,
            home_page: None,
            project_url: None,
            project_urls: None,
            author: None,
            author_email: None,
            maintainer: None,
            maintainer_email: None,
            classifiers: Some(vec![
                "Development Status :: 5 - Production/Stable".to_string(),
                "License :: OSI Approved :: MIT License".to_string(),
                "Programming Language :: Python :: 3".to_string(),
            ]),
            keywords: None,
            requires_dist: None,
        };

        let licenses = gateway.extract_licenses(&package_info);
        assert_eq!(licenses, vec!["MIT"]);
    }

    #[tokio::test]
    async fn test_extract_licenses_multiple_sources() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = PypiGateway::new(http_client);

        let package_info = PypiInfo {
            name: "test-package".to_string(),
            version: "1.0.0".to_string(),
            summary: None,
            description: None,
            license: Some("BSD".to_string()),
            home_page: None,
            project_url: None,
            project_urls: None,
            author: None,
            author_email: None,
            maintainer: None,
            maintainer_email: None,
            classifiers: Some(vec![
                "License :: OSI Approved :: MIT License".to_string(),
                "License :: OSI Approved :: Apache Software License".to_string(),
            ]),
            keywords: None,
            requires_dist: None,
        };

        let licenses = gateway.extract_licenses(&package_info);
        // Should include all unique licenses, sorted
        assert!(licenses.contains(&"BSD".to_string()));
        assert!(licenses.contains(&"MIT".to_string()));
        assert!(licenses.contains(&"Apache Software".to_string()));
    }

    #[test]
    fn test_package_metadata_conversion() {
        let response = PypiResponse {
            info: PypiInfo {
                name: "requests".to_string(),
                version: "2.28.0".to_string(),
                summary: Some("Python HTTP for Humans.".to_string()),
                description: None,
                license: Some("Apache 2.0".to_string()),
                home_page: Some("https://requests.readthedocs.io".to_string()),
                project_url: None,
                project_urls: Some([
                    ("Source".to_string(), "https://github.com/psf/requests".to_string()),
                ].into_iter().collect()),
                author: Some("Kenneth Reitz".to_string()),
                author_email: None,
                maintainer: None,
                maintainer_email: None,
                classifiers: None,
                keywords: None,
                requires_dist: Some(vec!["urllib3>=1.21.1".to_string()]),
            },
            urls: vec![],
        };

        let metadata: PackageMetadata = response.into();

        assert_eq!(metadata.name, "requests");
        assert_eq!(metadata.version, "2.28.0");
        assert_eq!(metadata.description, Some("Python HTTP for Humans.".to_string()));
        assert_eq!(metadata.homepage, Some("https://requests.readthedocs.io".to_string()));
        assert_eq!(metadata.repository, Some("https://github.com/psf/requests".to_string()));
        assert_eq!(metadata.authors, vec!["Kenneth Reitz"]);
        assert_eq!(metadata.dependencies, vec!["urllib3>=1.21.1"]);
        assert_eq!(metadata.registry.name, "PyPI");
    }
}