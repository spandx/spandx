use crate::gateway::circuit::CircuitBreakerRegistry;
use anyhow::Result;
use reqwest::{Client, Response};
use std::sync::Mutex;
use std::time::Duration;
use tracing::{debug, warn};
use url::Url;

#[derive(Debug)]
pub struct HttpClient {
    client: Client,
    circuit_breakers: Mutex<CircuitBreakerRegistry>,
    retry_count: u32,
    open_timeout: Duration,
    read_timeout: Duration,
}

impl HttpClient {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .connect_timeout(Duration::from_secs(5))
            .user_agent("spandx-rs/1.0.0")
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            circuit_breakers: Mutex::new(CircuitBreakerRegistry::default()),
            retry_count: 3,
            open_timeout: Duration::from_secs(1),
            read_timeout: Duration::from_secs(5),
        }
    }

    pub fn with_timeouts(mut self, open_timeout: Duration, read_timeout: Duration) -> Self {
        self.open_timeout = open_timeout;
        self.read_timeout = read_timeout;
        
        // Recreate client with new timeouts
        let client = Client::builder()
            .timeout(read_timeout)
            .connect_timeout(open_timeout)
            .user_agent("spandx-rs/1.0.0")
            .build()
            .expect("Failed to create HTTP client with custom timeouts");
        
        self.client = client;
        self
    }

    pub fn with_retry_count(mut self, retry_count: u32) -> Self {
        self.retry_count = retry_count;
        self
    }

    pub async fn get(&self, url: &str) -> Result<Response> {
        self.get_with_retries(url, false).await
    }

    pub async fn get_escaped(&self, url: &str) -> Result<Response> {
        self.get_with_retries(url, true).await
    }

    async fn get_with_retries(&self, url: &str, escape: bool) -> Result<Response> {
        if crate::is_airgap_mode() {
            return Err(anyhow::anyhow!("HTTP requests disabled in airgap mode"));
        }

        let final_url = if escape {
            self.escape_url(url)?
        } else {
            url.to_string()
        };

        let parsed_url = Url::parse(&final_url)?;
        let host = parsed_url.host_str().unwrap_or("unknown");

        // Check circuit breaker
        {
            let mut breakers = self.circuit_breakers.lock().unwrap();
            if !breakers.can_execute(host) {
                return Err(anyhow::anyhow!("Circuit breaker open for host: {}", host));
            }
        }

        let mut last_error = None;
        
        for attempt in 1..=self.retry_count {
            debug!("HTTP GET attempt {} for {}", attempt, final_url);
            
            match self.client.get(&final_url).send().await {
                Ok(response) => {
                    if response.status().is_success() {
                        // Record success in circuit breaker
                        {
                            let mut breakers = self.circuit_breakers.lock().unwrap();
                            breakers.record_success(host);
                        }
                        return Ok(response);
                    } else {
                        let status = response.status();
                        warn!("HTTP request failed with status {}: {}", status, final_url);
                        
                        // Don't retry on client errors (4xx)
                        if status.is_client_error() {
                            return Err(anyhow::anyhow!("Client error: {}", status));
                        }
                        
                        last_error = Some(anyhow::anyhow!("Server error: {}", status));
                    }
                }
                Err(e) => {
                    warn!("HTTP request error on attempt {}: {}", attempt, e);
                    last_error = Some(anyhow::anyhow!("Request error: {}", e));
                    
                    // Record failure in circuit breaker on final attempt
                    if attempt == self.retry_count {
                        let mut breakers = self.circuit_breakers.lock().unwrap();
                        breakers.record_failure(host);
                    }
                }
            }

            // Exponential backoff between retries
            if attempt < self.retry_count {
                let delay = Duration::from_millis(100 * 2_u64.pow(attempt - 1));
                tokio::time::sleep(delay).await;
            }
        }

        // Record failure in circuit breaker
        {
            let mut breakers = self.circuit_breakers.lock().unwrap();
            breakers.record_failure(host);
        }

        Err(last_error.unwrap_or_else(|| anyhow::anyhow!("All retries failed")))
    }

    pub fn ok(&self, response: &Response) -> bool {
        response.status().is_success()
    }

    fn escape_url(&self, url: &str) -> Result<String> {
        // Simple URL escaping - encode only the path components
        let parsed = Url::parse(url)?;
        let mut escaped = String::new();
        
        escaped.push_str(&format!("{}://", parsed.scheme()));
        
        if let Some(host) = parsed.host_str() {
            escaped.push_str(host);
        }
        
        if let Some(port) = parsed.port() {
            escaped.push_str(&format!(":{}", port));
        }
        
        // Encode path segments
        for segment in parsed.path_segments().unwrap_or("".split('/')) {
            if !segment.is_empty() {
                escaped.push('/');
                escaped.push_str(&urlencoding::encode(segment));
            }
        }
        
        if let Some(query) = parsed.query() {
            escaped.push('?');
            escaped.push_str(query);
        }
        
        if let Some(fragment) = parsed.fragment() {
            escaped.push('#');
            escaped.push_str(fragment);
        }
        
        Ok(escaped)
    }

    pub async fn get_json<T>(&self, url: &str) -> Result<T>
    where
        T: serde::de::DeserializeOwned,
    {
        let response = self.get(url).await?;
        let text = response.text().await?;
        let parsed: T = serde_json::from_str(&text)?;
        Ok(parsed)
    }

    pub async fn get_text(&self, url: &str) -> Result<String> {
        let response = self.get(url).await?;
        Ok(response.text().await?)
    }

    pub async fn get_bytes(&self, url: &str) -> Result<Vec<u8>> {
        let response = self.get(url).await?;
        Ok(response.bytes().await?.to_vec())
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
    use wiremock::{Mock, MockServer, ResponseTemplate};
    use wiremock::matchers::{method, path};

    #[tokio::test]
    async fn test_successful_get_request() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/test"))
            .respond_with(ResponseTemplate::new(200).set_body_string("success"))
            .mount(&mock_server)
            .await;

        let client = HttpClient::new();
        let url = format!("{}/test", mock_server.uri());
        let response = client.get(&url).await.unwrap();
        
        assert!(client.ok(&response));
        assert_eq!(response.text().await.unwrap(), "success");
    }

    #[tokio::test]
    async fn test_get_json() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/json"))
            .respond_with(ResponseTemplate::new(200).set_body_json(&serde_json::json!({
                "name": "test",
                "version": "1.0.0"
            })))
            .mount(&mock_server)
            .await;

        let client = HttpClient::new();
        let url = format!("{}/json", mock_server.uri());
        
        let result: serde_json::Value = client.get_json(&url).await.unwrap();
        assert_eq!(result["name"], "test");
        assert_eq!(result["version"], "1.0.0");
    }

    #[tokio::test]
    async fn test_retry_on_server_error() {
        let mock_server = MockServer::start().await;
        
        // First two requests fail, third succeeds
        Mock::given(method("GET"))
            .and(path("/retry"))
            .respond_with(ResponseTemplate::new(500))
            .up_to_n_times(2)
            .mount(&mock_server)
            .await;
            
        Mock::given(method("GET"))
            .and(path("/retry"))
            .respond_with(ResponseTemplate::new(200).set_body_string("success"))
            .mount(&mock_server)
            .await;

        let client = HttpClient::new().with_retry_count(3);
        let url = format!("{}/retry", mock_server.uri());
        let response = client.get(&url).await.unwrap();
        
        assert!(client.ok(&response));
    }

    #[tokio::test]
    async fn test_no_retry_on_client_error() {
        let mock_server = MockServer::start().await;
        
        Mock::given(method("GET"))
            .and(path("/client-error"))
            .respond_with(ResponseTemplate::new(404))
            .mount(&mock_server)
            .await;

        let client = HttpClient::new().with_retry_count(3);
        let url = format!("{}/client-error", mock_server.uri());
        let result = client.get(&url).await;
        
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Client error"));
    }

    #[test]
    fn test_url_escaping() {
        let client = HttpClient::new();
        
        let url = "https://example.com/path with spaces/file.json";
        let escaped = client.escape_url(url).unwrap();
        assert_eq!(escaped, "https://example.com/path%20with%20spaces/file.json");
        
        let url_with_query = "https://example.com/path?query=test value";
        let escaped = client.escape_url(url_with_query).unwrap();
        assert_eq!(escaped, "https://example.com/path?query=test value");
    }

    #[test]
    fn test_airgap_mode() {
        crate::set_airgap_mode(true);
        
        let rt = tokio::runtime::Runtime::new().unwrap();
        let client = HttpClient::new();
        
        let result = rt.block_on(client.get("https://example.com"));
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("airgap mode"));
        
        crate::set_airgap_mode(false);
    }
}