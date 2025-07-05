use std::time::{Duration, Instant};

#[derive(Debug, Clone)]
pub struct CircuitBreaker {
    failure_count: u32,
    failure_threshold: u32,
    reset_timeout: Duration,
    last_failure_time: Option<Instant>,
    state: CircuitBreakerState,
}

#[derive(Debug, Clone, PartialEq)]
enum CircuitBreakerState {
    Closed,
    Open,
    HalfOpen,
}

impl CircuitBreaker {
    pub fn new() -> Self {
        Self::with_threshold(5)
    }

    pub fn with_threshold(failure_threshold: u32) -> Self {
        Self {
            failure_count: 0,
            failure_threshold,
            reset_timeout: Duration::from_secs(60),
            last_failure_time: None,
            state: CircuitBreakerState::Closed,
        }
    }

    pub fn with_reset_timeout(mut self, timeout: Duration) -> Self {
        self.reset_timeout = timeout;
        self
    }

    pub fn is_open(&self) -> bool {
        match self.state {
            CircuitBreakerState::Open => {
                if let Some(last_failure) = self.last_failure_time {
                    Instant::now().duration_since(last_failure) < self.reset_timeout
                } else {
                    false
                }
            }
            CircuitBreakerState::HalfOpen => false,
            CircuitBreakerState::Closed => false,
        }
    }

    pub fn is_closed(&self) -> bool {
        matches!(self.state, CircuitBreakerState::Closed)
    }

    pub fn is_half_open(&self) -> bool {
        matches!(self.state, CircuitBreakerState::HalfOpen)
    }

    pub fn record_success(&mut self) {
        self.failure_count = 0;
        self.last_failure_time = None;
        self.state = CircuitBreakerState::Closed;
    }

    pub fn record_failure(&mut self) {
        self.failure_count += 1;
        self.last_failure_time = Some(Instant::now());

        if self.failure_count >= self.failure_threshold {
            self.state = CircuitBreakerState::Open;
        }
    }

    pub fn attempt_reset(&mut self) -> bool {
        if self.state == CircuitBreakerState::Open {
            if let Some(last_failure) = self.last_failure_time {
                if Instant::now().duration_since(last_failure) >= self.reset_timeout {
                    self.state = CircuitBreakerState::HalfOpen;
                    return true;
                }
            }
        }
        false
    }

    pub fn reset(&mut self) {
        self.failure_count = 0;
        self.last_failure_time = None;
        self.state = CircuitBreakerState::Closed;
    }

    pub fn failure_count(&self) -> u32 {
        self.failure_count
    }

    pub fn state_name(&self) -> &'static str {
        match self.state {
            CircuitBreakerState::Closed => "closed",
            CircuitBreakerState::Open => "open",
            CircuitBreakerState::HalfOpen => "half-open",
        }
    }
}

impl Default for CircuitBreaker {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::thread;

    #[test]
    fn test_circuit_breaker_closed_state() {
        let cb = CircuitBreaker::new();
        assert!(cb.is_closed());
        assert!(!cb.is_open());
        assert!(!cb.is_half_open());
        assert_eq!(cb.failure_count(), 0);
    }

    #[test]
    fn test_circuit_breaker_failure_threshold() {
        let mut cb = CircuitBreaker::with_threshold(3);
        
        // Record 2 failures - should stay closed
        cb.record_failure();
        cb.record_failure();
        assert!(cb.is_closed());
        assert_eq!(cb.failure_count(), 2);
        
        // Record 3rd failure - should open
        cb.record_failure();
        assert!(cb.is_open());
        assert_eq!(cb.failure_count(), 3);
    }

    #[test]
    fn test_circuit_breaker_success_resets() {
        let mut cb = CircuitBreaker::with_threshold(2);
        
        // Record failures
        cb.record_failure();
        cb.record_failure();
        assert!(cb.is_open());
        
        // Record success - should close
        cb.record_success();
        assert!(cb.is_closed());
        assert_eq!(cb.failure_count(), 0);
    }

    #[test]
    fn test_circuit_breaker_timeout() {
        let mut cb = CircuitBreaker::with_threshold(1)
            .with_reset_timeout(Duration::from_millis(100));
        
        // Trigger opening
        cb.record_failure();
        assert!(cb.is_open());
        
        // Should still be open immediately
        assert!(cb.is_open());
        
        // Wait for timeout
        thread::sleep(Duration::from_millis(150));
        
        // Should allow attempt reset
        assert!(cb.attempt_reset());
        assert!(cb.is_half_open());
    }

    #[test]
    fn test_circuit_breaker_manual_reset() {
        let mut cb = CircuitBreaker::with_threshold(1);
        
        cb.record_failure();
        assert!(cb.is_open());
        
        cb.reset();
        assert!(cb.is_closed());
        assert_eq!(cb.failure_count(), 0);
    }

    #[test]
    fn test_circuit_breaker_state_names() {
        let mut cb = CircuitBreaker::new();
        
        assert_eq!(cb.state_name(), "closed");
        
        cb.record_failure();
        cb.record_failure();
        cb.record_failure();
        cb.record_failure();
        cb.record_failure();
        assert_eq!(cb.state_name(), "open");
        
        cb.state = CircuitBreakerState::HalfOpen;
        assert_eq!(cb.state_name(), "half-open");
    }
}