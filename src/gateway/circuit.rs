use std::collections::HashMap;
use std::time::{Duration, Instant};
use tracing::{debug, warn};

#[derive(Debug, Clone, PartialEq)]
pub enum CircuitState {
    Closed,  // Working normally
    Open,    // Failing, requests blocked
}

#[derive(Debug, Clone)]
pub struct CircuitBreaker {
    state: CircuitState,
    failure_count: u32,
    last_failure: Option<Instant>,
    failure_threshold: u32,
    recovery_timeout: Duration,
}

impl CircuitBreaker {
    pub fn new(failure_threshold: u32, recovery_timeout: Duration) -> Self {
        Self {
            state: CircuitState::Closed,
            failure_count: 0,
            last_failure: None,
            failure_threshold,
            recovery_timeout,
        }
    }

    pub fn can_execute(&mut self) -> bool {
        match self.state {
            CircuitState::Closed => true,
            CircuitState::Open => {
                if let Some(last_failure) = self.last_failure {
                    if last_failure.elapsed() >= self.recovery_timeout {
                        debug!("Circuit breaker attempting recovery");
                        self.state = CircuitState::Closed;
                        self.failure_count = 0;
                        true
                    } else {
                        false
                    }
                } else {
                    true
                }
            }
        }
    }

    pub fn record_success(&mut self) {
        if self.state == CircuitState::Open {
            debug!("Circuit breaker recovered - closing circuit");
        }
        self.state = CircuitState::Closed;
        self.failure_count = 0;
        self.last_failure = None;
    }

    pub fn record_failure(&mut self) {
        self.failure_count += 1;
        self.last_failure = Some(Instant::now());

        if self.failure_count >= self.failure_threshold && self.state == CircuitState::Closed {
            warn!(
                "Circuit breaker opening after {} failures", 
                self.failure_count
            );
            self.state = CircuitState::Open;
        }
    }

    pub fn state(&self) -> &CircuitState {
        &self.state
    }

    pub fn failure_count(&self) -> u32 {
        self.failure_count
    }
}

#[derive(Debug)]
pub struct CircuitBreakerRegistry {
    breakers: HashMap<String, CircuitBreaker>,
    failure_threshold: u32,
    recovery_timeout: Duration,
}

impl CircuitBreakerRegistry {
    pub fn new(failure_threshold: u32, recovery_timeout: Duration) -> Self {
        Self {
            breakers: HashMap::new(),
            failure_threshold,
            recovery_timeout,
        }
    }

    pub fn get_or_create(&mut self, host: &str) -> &mut CircuitBreaker {
        self.breakers
            .entry(host.to_string())
            .or_insert_with(|| CircuitBreaker::new(self.failure_threshold, self.recovery_timeout))
    }

    pub fn can_execute(&mut self, host: &str) -> bool {
        self.get_or_create(host).can_execute()
    }

    pub fn record_success(&mut self, host: &str) {
        self.get_or_create(host).record_success();
    }

    pub fn record_failure(&mut self, host: &str) {
        self.get_or_create(host).record_failure();
    }
}

impl Default for CircuitBreakerRegistry {
    fn default() -> Self {
        Self::new(3, Duration::from_secs(30))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::thread;

    #[test]
    fn test_circuit_breaker_starts_closed() {
        let mut breaker = CircuitBreaker::new(3, Duration::from_millis(100));
        assert_eq!(breaker.state(), &CircuitState::Closed);
        assert!(breaker.can_execute());
    }

    #[test]
    fn test_circuit_breaker_opens_after_failures() {
        let mut breaker = CircuitBreaker::new(3, Duration::from_millis(100));
        
        // Record failures
        breaker.record_failure();
        assert_eq!(breaker.state(), &CircuitState::Closed);
        
        breaker.record_failure();
        assert_eq!(breaker.state(), &CircuitState::Closed);
        
        breaker.record_failure();
        assert_eq!(breaker.state(), &CircuitState::Open);
        assert!(!breaker.can_execute());
    }

    #[test]
    fn test_circuit_breaker_recovery() {
        let mut breaker = CircuitBreaker::new(2, Duration::from_millis(50));
        
        // Open the circuit
        breaker.record_failure();
        breaker.record_failure();
        assert_eq!(breaker.state(), &CircuitState::Open);
        
        // Wait for recovery timeout
        thread::sleep(Duration::from_millis(60));
        
        // Should allow execution after timeout
        assert!(breaker.can_execute());
        assert_eq!(breaker.state(), &CircuitState::Closed);
    }

    #[test]
    fn test_circuit_breaker_success_resets() {
        let mut breaker = CircuitBreaker::new(3, Duration::from_millis(100));
        
        // Record some failures
        breaker.record_failure();
        breaker.record_failure();
        assert_eq!(breaker.failure_count(), 2);
        
        // Success should reset
        breaker.record_success();
        assert_eq!(breaker.failure_count(), 0);
        assert_eq!(breaker.state(), &CircuitState::Closed);
    }

    #[test]
    fn test_circuit_breaker_registry() {
        let mut registry = CircuitBreakerRegistry::new(2, Duration::from_millis(100));
        
        // Test different hosts
        assert!(registry.can_execute("example.com"));
        assert!(registry.can_execute("api.example.com"));
        
        // Fail one host
        registry.record_failure("example.com");
        registry.record_failure("example.com");
        
        // Should block only the failed host
        assert!(!registry.can_execute("example.com"));
        assert!(registry.can_execute("api.example.com"));
        
        // Success should restore
        registry.record_success("example.com");
        assert!(registry.can_execute("example.com"));
    }
}