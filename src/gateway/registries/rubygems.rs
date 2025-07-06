use crate::core::{Dependency, PackageManager};
use crate::gateway::traits::{Gateway, GatewayError, GatewayResult, PackageMetadata, RegistryInfo};
use crate::gateway::HttpClient;
use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::{debug, warn};

/// Gateway for fetching package information from RubyGems.org
#[derive(Debug)]
pub struct RubyGemsGateway {
    http_client: Arc<HttpClient>,
    base_url: String,
    api_base_url: String,
}

impl RubyGemsGateway {
    pub fn new(http_client: Arc<HttpClient>) -> Self {
        Self {
            http_client,
            base_url: "https://rubygems.org".to_string(),
            api_base_url: "https://rubygems.org/api/v2".to_string(),
        }
    }

    pub fn with_custom_url(http_client: Arc<HttpClient>, base_url: String) -> Self {
        let api_base_url = format!("{}/api/v2", base_url);
        Self {
            http_client,
            base_url,
            api_base_url,
        }
    }

    async fn get_gem_info(&self, name: &str, version: &str) -> GatewayResult<RubyGemsResponse> {
        let url = format!("{}/rubygems/{}/versions/{}.json", self.api_base_url, name, version);
        
        debug!("Fetching RubyGems info from: {}", url);
        
        match self.http_client.get_json::<RubyGemsResponse>(&url).await {
            Ok(response) => Ok(response),
            Err(e) => {
                warn!("Failed to fetch RubyGems info for {}@{}: {}", name, version, e);
                Err(GatewayError::PackageNotFound {
                    name: name.to_string(),
                    version: version.to_string(),
                })
            }
        }
    }

    fn extract_licenses(&self, gem_info: &RubyGemsResponse) -> Vec<String> {
        let mut licenses = Vec::new();
        
        // Extract from licenses array
        if let Some(gem_licenses) = &gem_info.licenses {
            for license in gem_licenses {
                if !license.trim().is_empty() {
                    licenses.push(license.clone());
                }
            }
        }
        
        // Extract from license field (singular)
        if let Some(license) = &gem_info.license {
            if !license.trim().is_empty() && !licenses.contains(license) {
                licenses.push(license.clone());
            }
        }
        
        // Remove duplicates but preserve order
        licenses.dedup();
        
        debug!("Extracted licenses for {}: {:?}", gem_info.name, licenses);
        licenses
    }

    pub async fn get_all_gems(&self) -> GatewayResult<Vec<(String, String)>> {
        let url = "https://index.rubygems.org/versions";
        
        debug!("Fetching all gems from: {}", url);
        
        match self.http_client.get_text(url).await {
            Ok(content) => {
                let mut gems = Vec::new();
                
                for line in content.lines().skip(2) { // Skip the header lines
                    let line_content = if line.starts_with('-') {
                        &line[1..] // Remove leading "-"
                    } else {
                        line
                    };
                    
                    let parts: Vec<&str> = line_content.trim().split(' ').collect();
                    if parts.len() >= 2 {
                        let gem_name = parts[0].to_string();
                        let versions_str = parts[1];
                        
                        // Extract ALL versions, not just the latest
                        for version in versions_str.split(',') {
                            gems.push((gem_name.clone(), version.to_string()));
                        }
                    }
                }
                
                debug!("Found {} gem versions in index", gems.len());
                Ok(gems)
            }
            Err(e) => {
                warn!("Failed to fetch gems index: {}", e);
                Err(GatewayError::Registry {
                    message: format!("Failed to fetch gems index: {}", e),
                })
            }
        }
    }
}

#[async_trait]
impl Gateway for RubyGemsGateway {
    fn matches(&self, dependency: &Dependency) -> bool {
        if let Some(source) = &dependency.source {
            let pm = PackageManager::from_source(source);
            pm.is_ruby()
        } else {
            false
        }
    }

    async fn licenses_for(&self, dependency: &Dependency) -> Result<Vec<String>> {
        let gem_info = self.get_gem_info(&dependency.name, &dependency.version).await?;
        Ok(self.extract_licenses(&gem_info))
    }

    fn name(&self) -> &'static str {
        "RubyGems"
    }

    fn base_url(&self) -> &str {
        &self.base_url
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct RubyGemsResponse {
    name: String,
    version: String,
    licenses: Option<Vec<String>>,
    license: Option<String>,
    description: Option<String>,
    homepage_uri: Option<String>,
    source_code_uri: Option<String>,
    bug_tracker_uri: Option<String>,
    documentation_uri: Option<String>,
    mailing_list_uri: Option<String>,
    wiki_uri: Option<String>,
    authors: Option<String>,
    dependencies: Option<RubyGemsDependencies>,
}

#[derive(Debug, Serialize, Deserialize)]
struct RubyGemsDependencies {
    development: Option<Vec<RubyGemsDependency>>,
    runtime: Option<Vec<RubyGemsDependency>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct RubyGemsDependency {
    name: String,
    requirements: String,
}

impl From<RubyGemsResponse> for PackageMetadata {
    fn from(response: RubyGemsResponse) -> Self {
        let registry = RegistryInfo::new(
            "RubyGems".to_string(),
            "https://rubygems.org".to_string(),
            "rubygems".to_string(),
        );

        let mut licenses = Vec::new();
        if let Some(gem_licenses) = response.licenses {
            licenses.extend(gem_licenses);
        }
        if let Some(license) = response.license {
            if !license.trim().is_empty() && !licenses.contains(&license) {
                licenses.push(license);
            }
        }

        let authors = response
            .authors
            .map(|a| vec![a])
            .unwrap_or_default();

        PackageMetadata::new(response.name, response.version, registry)
            .with_licenses(licenses)
            .with_description(response.description)
            .with_homepage(response.homepage_uri)
            .with_repository(response.source_code_uri)
            .with_authors(authors)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::{Mock, MockServer, ResponseTemplate};
    use wiremock::matchers::{method, path};

    #[tokio::test]
    async fn test_rubygems_gateway_matches() {
        let http_client = Arc::new(HttpClient::new());
        let gateway = RubyGemsGateway::new(http_client);

        let ruby_dep = Dependency::new("rails".to_string(), "7.0.0".to_string())
            .with_source("rubygems".to_string());

        let npm_dep = Dependency::new("lodash".to_string(), "4.17.21".to_string())
            .with_source("npm".to_string());

        assert!(gateway.matches(&ruby_dep));
        assert!(!gateway.matches(&npm_dep));
    }

    #[tokio::test]
    async fn test_get_gem_info() {
        let mock_server = MockServer::start().await;
        let http_client = Arc::new(HttpClient::new());
        let gateway = RubyGemsGateway::with_custom_url(
            http_client,
            mock_server.uri(),
        );

        let response_body = serde_json::json!({
            "name": "rails",
            "version": "7.0.0",
            "licenses": ["MIT"],
            "description": "Ruby on Rails",
            "homepage_uri": "https://rubyonrails.org/"
        });

        Mock::given(method("GET"))
            .and(path("/api/v2/rubygems/rails/versions/7.0.0.json"))
            .respond_with(ResponseTemplate::new(200).set_body_json(&response_body))
            .mount(&mock_server)
            .await;

        let dependency = Dependency::new("rails".to_string(), "7.0.0".to_string())
            .with_source("rubygems".to_string());

        let licenses = gateway.licenses_for(&dependency).await.unwrap();
        assert_eq!(licenses, vec!["MIT"]);
    }

    #[tokio::test]
    async fn test_extract_licenses_multiple_sources() {
        let response = RubyGemsResponse {
            name: "test-gem".to_string(),
            version: "1.0.0".to_string(),
            licenses: Some(vec!["MIT".to_string(), "Apache-2.0".to_string()]),
            license: Some("BSD-3-Clause".to_string()),
            description: None,
            homepage_uri: None,
            source_code_uri: None,
            bug_tracker_uri: None,
            documentation_uri: None,
            mailing_list_uri: None,
            wiki_uri: None,
            authors: None,
            dependencies: None,
        };

        let http_client = Arc::new(HttpClient::new());
        let gateway = RubyGemsGateway::new(http_client);
        let licenses = gateway.extract_licenses(&response);

        // Should include all unique licenses, sorted
        assert_eq!(licenses, vec!["Apache-2.0", "BSD-3-Clause", "MIT"]);
    }

    #[tokio::test]
    async fn test_package_not_found() {
        let mock_server = MockServer::start().await;
        let http_client = Arc::new(HttpClient::new());
        let gateway = RubyGemsGateway::with_custom_url(
            http_client,
            mock_server.uri(),
        );

        Mock::given(method("GET"))
            .and(path("/api/v2/rubygems/nonexistent/versions/1.0.0.json"))
            .respond_with(ResponseTemplate::new(404))
            .mount(&mock_server)
            .await;

        let dependency = Dependency::new("nonexistent".to_string(), "1.0.0".to_string())
            .with_source("rubygems".to_string());

        let result = gateway.licenses_for(&dependency).await;
        assert!(result.is_err());
    }

    #[test]
    fn test_package_metadata_conversion() {
        let response = RubyGemsResponse {
            name: "rails".to_string(),
            version: "7.0.0".to_string(),
            licenses: Some(vec!["MIT".to_string()]),
            license: None,
            description: Some("Ruby on Rails web framework".to_string()),
            homepage_uri: Some("https://rubyonrails.org/".to_string()),
            source_code_uri: Some("https://github.com/rails/rails".to_string()),
            bug_tracker_uri: None,
            documentation_uri: None,
            mailing_list_uri: None,
            wiki_uri: None,
            authors: Some("DHH".to_string()),
            dependencies: None,
        };

        let metadata: PackageMetadata = response.into();

        assert_eq!(metadata.name, "rails");
        assert_eq!(metadata.version, "7.0.0");
        assert_eq!(metadata.licenses, vec!["MIT"]);
        assert_eq!(metadata.description, Some("Ruby on Rails web framework".to_string()));
        assert_eq!(metadata.homepage, Some("https://rubyonrails.org/".to_string()));
        assert_eq!(metadata.repository, Some("https://github.com/rails/rails".to_string()));
        assert_eq!(metadata.authors, vec!["DHH"]);
        assert_eq!(metadata.registry.name, "RubyGems");
    }
}