use reqwest::{Client, Response, StatusCode};
use std::collections::HashMap;
use std::time::Duration;
use thiserror::Error;
use tracing::debug;
use url::Url;

use super::circuit::CircuitBreaker;

#[derive(Error, Debug)]
pub enum HttpError {
    #[error("Request failed: {0}")]
    RequestFailed(#[from] reqwest::Error),
    #[error("Circuit breaker open for host: {0}")]
    CircuitBreakerOpen(String),
    #[error("Too many redirects")]
    TooManyRedirects,
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    #[error("HTTP error {status}: {message}")]
    HttpStatus { status: StatusCode, message: String },
    #[error("Network operation disabled in airgap mode")]
    AirgapMode,
}

pub type HttpResult<T> = Result<T, HttpError>;

#[derive(Debug, Clone)]
pub struct HttpClient {
    client: Client,
    circuit_breakers: HashMap<String, CircuitBreaker>,
    max_redirects: usize,
}

impl HttpClient {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .connect_timeout(Duration::from_secs(10))
            .redirect(reqwest::redirect::Policy::none()) // Handle redirects manually
            .user_agent("spandx-rs/0.1.0")
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            circuit_breakers: HashMap::new(),
            max_redirects: 3,
        }
    }

    pub async fn get(&mut self, url: &str) -> HttpResult<Response> {
        if crate::is_airgap_mode() {
            return Err(HttpError::AirgapMode);
        }

        let parsed_url = Url::parse(url)
            .map_err(|_| HttpError::InvalidUrl(url.to_string()))?;

        let host = parsed_url.host_str()
            .ok_or_else(|| HttpError::InvalidUrl("No host in URL".to_string()))?
            .to_string();

        // Check circuit breaker state first
        let is_open = self.circuit_breakers
            .get(&host)
            .map(|cb| cb.is_open())
            .unwrap_or(false);

        if is_open {
            return Err(HttpError::CircuitBreakerOpen(host));
        }

        // Make the request
        let result = self.make_request(url, 0).await;

        // Update circuit breaker based on result
        let circuit_breaker = self.circuit_breakers
            .entry(host)
            .or_insert_with(CircuitBreaker::new);

        match &result {
            Ok(_) => circuit_breaker.record_success(),
            Err(_) => circuit_breaker.record_failure(),
        }

        result
    }

    async fn make_request(&self, url: &str, redirect_count: usize) -> HttpResult<Response> {
        if redirect_count > self.max_redirects {
            return Err(HttpError::TooManyRedirects);
        }

        debug!("Making HTTP GET request to: {}", url);
        
        let response = self.client
            .get(url)
            .send()
            .await?;

        let status = response.status();
        
        if status.is_redirection() {
            if let Some(location) = response.headers().get("location") {
                let location_str = location.to_str()
                    .map_err(|_| HttpError::InvalidUrl("Invalid redirect location".to_string()))?;
                
                // Handle relative URLs
                let redirect_url = if location_str.starts_with("http") {
                    location_str.to_string()
                } else {
                    let base = Url::parse(url)
                        .map_err(|_| HttpError::InvalidUrl(url.to_string()))?;
                    base.join(location_str)
                        .map_err(|_| HttpError::InvalidUrl("Invalid redirect URL".to_string()))?
                        .to_string()
                };

                debug!("Following redirect to: {}", redirect_url);
                return Box::pin(self.make_request(&redirect_url, redirect_count + 1)).await;
            }
        }

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_default();
            return Err(HttpError::HttpStatus {
                status,
                message: error_text,
            });
        }

        Ok(response)
    }

    pub async fn get_json<T>(&mut self, url: &str) -> HttpResult<T>
    where
        T: serde::de::DeserializeOwned,
    {
        let response = self.get(url).await?;
        let json = response.json::<T>().await?;
        Ok(json)
    }

    pub async fn get_text(&mut self, url: &str) -> HttpResult<String> {
        let response = self.get(url).await?;
        let text = response.text().await?;
        Ok(text)
    }

    pub fn reset_circuit_breaker(&mut self, host: &str) {
        if let Some(cb) = self.circuit_breakers.get_mut(host) {
            cb.reset();
        }
    }

    pub fn get_circuit_breaker_status(&self, host: &str) -> Option<bool> {
        self.circuit_breakers.get(host).map(|cb| cb.is_open())
    }
}

impl Default for HttpClient {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::matchers::{method, path};
    use wiremock::{Mock, MockServer, ResponseTemplate};

    #[tokio::test]
    async fn test_http_client_get() {
        let mock_server = MockServer::start().await;

        Mock::given(method("GET"))
            .and(path("/test"))
            .respond_with(ResponseTemplate::new(200).set_body_string("Hello, World!"))
            .mount(&mock_server)
            .await;

        let mut client = HttpClient::new();
        let url = format!("{}/test", mock_server.uri());
        
        let response = client.get(&url).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        
        let text = response.text().await.unwrap();
        assert_eq!(text, "Hello, World!");
    }

    #[tokio::test]
    async fn test_http_client_json() {
        let mock_server = MockServer::start().await;

        Mock::given(method("GET"))
            .and(path("/json"))
            .respond_with(
                ResponseTemplate::new(200)
                    .set_body_json(serde_json::json!({"message": "Hello, JSON!"}))
            )
            .mount(&mock_server)
            .await;

        let mut client = HttpClient::new();
        let url = format!("{}/json", mock_server.uri());
        
        let json: serde_json::Value = client.get_json(&url).await.unwrap();
        assert_eq!(json["message"], "Hello, JSON!");
    }

    #[tokio::test]
    async fn test_http_client_redirect() {
        let mock_server = MockServer::start().await;

        Mock::given(method("GET"))
            .and(path("/redirect"))
            .respond_with(
                ResponseTemplate::new(302)
                    .insert_header("location", format!("{}/final", mock_server.uri()).as_str())
            )
            .mount(&mock_server)
            .await;

        Mock::given(method("GET"))
            .and(path("/final"))
            .respond_with(ResponseTemplate::new(200).set_body_string("Final destination"))
            .mount(&mock_server)
            .await;

        let mut client = HttpClient::new();
        let url = format!("{}/redirect", mock_server.uri());
        
        let response = client.get(&url).await.unwrap();
        let text = response.text().await.unwrap();
        assert_eq!(text, "Final destination");
    }

    #[tokio::test]
    async fn test_airgap_mode() {
        crate::set_airgap_mode(true);
        
        let mut client = HttpClient::new();
        let result = client.get("https://example.com").await;
        
        assert!(matches!(result, Err(HttpError::AirgapMode)));
        
        // Reset for other tests
        crate::set_airgap_mode(false);
    }
}