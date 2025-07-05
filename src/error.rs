use std::fmt;
use thiserror::Error;

/// Comprehensive error types for Spandx
#[derive(Error, Debug)]
pub enum SpandxError {
    // Core dependency and license errors
    #[error("Dependency parsing failed: {message}")]
    DependencyParseError { message: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    #[error("License detection failed for {package}@{version}: {reason}")]
    LicenseDetectionError { package: String, version: String, reason: String },
    
    #[error("Invalid license expression: {expression}")]
    InvalidLicenseExpression { expression: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    // File system and I/O errors
    #[error("File operation failed: {operation} on {path}")]
    FileSystemError { operation: String, path: String, source: std::io::Error },
    
    #[error("File not found: {path}")]
    FileNotFound { path: String },
    
    #[error("Directory not found: {path}")]
    DirectoryNotFound { path: String },
    
    #[error("Permission denied: {path}")]
    PermissionDenied { path: String },
    
    // Network and HTTP errors
    #[error("Network request failed: {method} {url}")]
    NetworkError { method: String, url: String, source: reqwest::Error },
    
    #[error("HTTP error {status}: {url}")]
    HttpError { status: u16, url: String, message: String },
    
    #[error("Request timeout: {url} (after {timeout_ms}ms)")]
    RequestTimeout { url: String, timeout_ms: u64 },
    
    #[error("Circuit breaker open for {service}: {reason}")]
    CircuitBreakerOpen { service: String, reason: String },
    
    // Git operations errors
    #[error("Git operation failed: {operation} on {repository}")]
    GitError { operation: String, repository: String, source: git2::Error },
    
    #[error("Git repository not found: {path}")]
    GitRepositoryNotFound { path: String },
    
    #[error("Git authentication failed: {repository}")]
    GitAuthenticationError { repository: String },
    
    #[error("Git merge conflict in {repository}: {files:?}")]
    GitMergeConflict { repository: String, files: Vec<String> },
    
    // Cache errors
    #[error("Cache operation failed: {operation}")]
    CacheError { operation: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    #[error("Cache corruption detected: {details}")]
    CacheCorruption { details: String },
    
    #[error("Cache index rebuild failed for {package_manager}: {reason}")]
    CacheIndexError { package_manager: String, reason: String },
    
    #[error("Cache capacity exceeded: {current_size} > {max_size}")]
    CacheCapacityError { current_size: usize, max_size: usize },
    
    // Parser errors
    #[error("Failed to parse {file_type} file: {file_path}")]
    ParseError { file_type: String, file_path: String, source: Box<dyn std::error::Error + Send + Sync> },
    
    #[error("Invalid {format} format in {file_path}: {reason}")]
    InvalidFormatError { format: String, file_path: String, reason: String },
    
    #[error("Missing required field '{field}' in {file_path}")]
    MissingFieldError { field: String, file_path: String },
    
    #[error("Unsupported file type: {file_type} (supported: {supported:?})")]
    UnsupportedFileType { file_type: String, supported: Vec<String> },
    
    // Configuration errors
    #[error("Configuration error: {message}")]
    ConfigError { message: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    #[error("Invalid configuration value for '{key}': {value}")]
    InvalidConfigValue { key: String, value: String },
    
    #[error("Missing required configuration: {key}")]
    MissingConfig { key: String },
    
    // SPDX and catalog errors
    #[error("SPDX catalog error: {message}")]
    SpdxError { message: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    #[error("SPDX license not found: {license_id}")]
    SpdxLicenseNotFound { license_id: String },
    
    #[error("SPDX expression parsing failed: {expression}")]
    SpdxExpressionError { expression: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    // CLI and user interface errors
    #[error("Invalid command arguments: {message}")]
    InvalidArguments { message: String },
    
    #[error("Operation cancelled by user")]
    UserCancelled,
    
    #[error("CLI error: {message}")]
    CliError { message: String },
    
    // Gateway and registry errors
    #[error("Package registry error for {registry}: {message}")]
    RegistryError { registry: String, message: String, source: Option<Box<dyn std::error::Error + Send + Sync>> },
    
    #[error("Package not found: {package}@{version} in {registry}")]
    PackageNotFound { package: String, version: String, registry: String },
    
    #[error("Registry authentication failed: {registry}")]
    RegistryAuthError { registry: String },
    
    #[error("Rate limit exceeded for {registry}: retry after {retry_after_ms}ms")]
    RateLimitExceeded { registry: String, retry_after_ms: u64 },
    
    // Validation and data errors
    #[error("Validation failed: {field} - {reason}")]
    ValidationError { field: String, reason: String },
    
    #[error("Data corruption detected: {details}")]
    DataCorruption { details: String },
    
    #[error("Serialization error: {message}")]
    SerializationError { message: String, source: Box<dyn std::error::Error + Send + Sync> },
    
    // Internal errors
    #[error("Internal error: {message}")]
    InternalError { message: String },
    
    #[error("Feature not implemented: {feature}")]
    NotImplemented { feature: String },
    
    #[error("Resource exhausted: {resource}")]
    ResourceExhausted { resource: String },
    
    // Compatibility and migration errors
    #[error("Version compatibility error: requires {required}, found {found}")]
    VersionCompatibilityError { required: String, found: String },
    
    #[error("Migration failed from {from_version} to {to_version}: {reason}")]
    MigrationError { from_version: String, to_version: String, reason: String },
}

impl SpandxError {
    /// Create a dependency parse error with context
    pub fn dependency_parse(message: impl Into<String>) -> Self {
        Self::DependencyParseError { 
            message: message.into(), 
            source: None 
        }
    }
    
    /// Create a dependency parse error with source
    pub fn dependency_parse_with_source(message: impl Into<String>, source: impl std::error::Error + Send + Sync + 'static) -> Self {
        Self::DependencyParseError { 
            message: message.into(), 
            source: Some(Box::new(source)) 
        }
    }
    
    /// Create a license detection error
    pub fn license_detection(package: impl Into<String>, version: impl Into<String>, reason: impl Into<String>) -> Self {
        Self::LicenseDetectionError {
            package: package.into(),
            version: version.into(),
            reason: reason.into(),
        }
    }
    
    /// Create a file system error
    pub fn file_system(operation: impl Into<String>, path: impl Into<String>, source: std::io::Error) -> Self {
        Self::FileSystemError {
            operation: operation.into(),
            path: path.into(),
            source,
        }
    }
    
    /// Create a network error
    pub fn network(method: impl Into<String>, url: impl Into<String>, source: reqwest::Error) -> Self {
        Self::NetworkError {
            method: method.into(),
            url: url.into(),
            source,
        }
    }
    
    /// Create a git error
    pub fn git(operation: impl Into<String>, repository: impl Into<String>, source: git2::Error) -> Self {
        Self::GitError {
            operation: operation.into(),
            repository: repository.into(),
            source,
        }
    }
    
    /// Create a cache error
    pub fn cache(operation: impl Into<String>) -> Self {
        Self::CacheError {
            operation: operation.into(),
            source: None,
        }
    }
    
    /// Create a cache error with source
    pub fn cache_with_source(operation: impl Into<String>, source: impl std::error::Error + Send + Sync + 'static) -> Self {
        Self::CacheError {
            operation: operation.into(),
            source: Some(Box::new(source)),
        }
    }
    
    /// Create a parse error
    pub fn parse(file_type: impl Into<String>, file_path: impl Into<String>, source: impl std::error::Error + Send + Sync + 'static) -> Self {
        Self::ParseError {
            file_type: file_type.into(),
            file_path: file_path.into(),
            source: Box::new(source),
        }
    }
    
    /// Create a registry error
    pub fn registry(registry: impl Into<String>, message: impl Into<String>) -> Self {
        Self::RegistryError {
            registry: registry.into(),
            message: message.into(),
            source: None,
        }
    }
    
    /// Create a validation error
    pub fn validation(field: impl Into<String>, reason: impl Into<String>) -> Self {
        Self::ValidationError {
            field: field.into(),
            reason: reason.into(),
        }
    }
    
    /// Check if error is retriable
    pub fn is_retriable(&self) -> bool {
        match self {
            Self::NetworkError { .. } => true,
            Self::RequestTimeout { .. } => true,
            Self::HttpError { status, .. } => *status >= 500 || *status == 429,
            Self::GitError { .. } => true,
            Self::CacheError { .. } => false, // Cache errors usually indicate corruption
            Self::RateLimitExceeded { .. } => true,
            Self::CircuitBreakerOpen { .. } => false, // Circuit breaker prevents retries
            _ => false,
        }
    }
    
    /// Get retry delay in milliseconds
    pub fn retry_delay_ms(&self) -> Option<u64> {
        match self {
            Self::NetworkError { .. } => Some(1000), // 1 second
            Self::RequestTimeout { .. } => Some(5000), // 5 seconds
            Self::HttpError { status, .. } => {
                match *status {
                    429 => Some(60000), // 1 minute for rate limiting
                    502 | 503 | 504 => Some(2000), // 2 seconds for server errors
                    _ => None,
                }
            }
            Self::RateLimitExceeded { retry_after_ms, .. } => Some(*retry_after_ms),
            _ => None,
        }
    }
    
    /// Get user-friendly error message
    pub fn user_message(&self) -> String {
        match self {
            Self::FileNotFound { path } => format!("File not found: {}", path),
            Self::DirectoryNotFound { path } => format!("Directory not found: {}", path),
            Self::PermissionDenied { path } => format!("Permission denied accessing: {}", path),
            Self::NetworkError { url, .. } => format!("Network error accessing: {}", url),
            Self::PackageNotFound { package, version, registry } => {
                format!("Package {}@{} not found in {}", package, version, registry)
            }
            Self::InvalidArguments { message } => message.clone(),
            Self::UserCancelled => "Operation cancelled".to_string(),
            Self::ConfigError { message, .. } => format!("Configuration error: {}", message),
            Self::NotImplemented { feature } => format!("Feature not yet implemented: {}", feature),
            _ => self.to_string(),
        }
    }
    
    /// Get error category for metrics and logging
    pub fn category(&self) -> ErrorCategory {
        match self {
            Self::DependencyParseError { .. } | Self::LicenseDetectionError { .. } | Self::InvalidLicenseExpression { .. } => ErrorCategory::Parse,
            Self::FileSystemError { .. } | Self::FileNotFound { .. } | Self::DirectoryNotFound { .. } | Self::PermissionDenied { .. } => ErrorCategory::FileSystem,
            Self::NetworkError { .. } | Self::HttpError { .. } | Self::RequestTimeout { .. } | Self::CircuitBreakerOpen { .. } => ErrorCategory::Network,
            Self::GitError { .. } | Self::GitRepositoryNotFound { .. } | Self::GitAuthenticationError { .. } | Self::GitMergeConflict { .. } => ErrorCategory::Git,
            Self::CacheError { .. } | Self::CacheCorruption { .. } | Self::CacheIndexError { .. } | Self::CacheCapacityError { .. } => ErrorCategory::Cache,
            Self::ParseError { .. } | Self::InvalidFormatError { .. } | Self::MissingFieldError { .. } | Self::UnsupportedFileType { .. } => ErrorCategory::Parse,
            Self::ConfigError { .. } | Self::InvalidConfigValue { .. } | Self::MissingConfig { .. } => ErrorCategory::Config,
            Self::SpdxError { .. } | Self::SpdxLicenseNotFound { .. } | Self::SpdxExpressionError { .. } => ErrorCategory::Spdx,
            Self::InvalidArguments { .. } | Self::UserCancelled | Self::CliError { .. } => ErrorCategory::Cli,
            Self::RegistryError { .. } | Self::PackageNotFound { .. } | Self::RegistryAuthError { .. } | Self::RateLimitExceeded { .. } => ErrorCategory::Registry,
            Self::ValidationError { .. } | Self::DataCorruption { .. } | Self::SerializationError { .. } => ErrorCategory::Validation,
            Self::InternalError { .. } | Self::NotImplemented { .. } | Self::ResourceExhausted { .. } => ErrorCategory::Internal,
            Self::VersionCompatibilityError { .. } | Self::MigrationError { .. } => ErrorCategory::Compatibility,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ErrorCategory {
    Parse,
    FileSystem,
    Network,
    Git,
    Cache,
    Config,
    Spdx,
    Cli,
    Registry,
    Validation,
    Internal,
    Compatibility,
}

impl fmt::Display for ErrorCategory {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Parse => write!(f, "parse"),
            Self::FileSystem => write!(f, "filesystem"),
            Self::Network => write!(f, "network"),
            Self::Git => write!(f, "git"),
            Self::Cache => write!(f, "cache"),
            Self::Config => write!(f, "config"),
            Self::Spdx => write!(f, "spdx"),
            Self::Cli => write!(f, "cli"),
            Self::Registry => write!(f, "registry"),
            Self::Validation => write!(f, "validation"),
            Self::Internal => write!(f, "internal"),
            Self::Compatibility => write!(f, "compatibility"),
        }
    }
}

/// Result type for Spandx operations
pub type SpandxResult<T> = Result<T, SpandxError>;

/// Convert common errors to SpandxError
impl From<std::io::Error> for SpandxError {
    fn from(err: std::io::Error) -> Self {
        match err.kind() {
            std::io::ErrorKind::NotFound => Self::FileNotFound { 
                path: err.to_string() 
            },
            std::io::ErrorKind::PermissionDenied => Self::PermissionDenied { 
                path: err.to_string() 
            },
            _ => Self::FileSystemError {
                operation: "unknown".to_string(),
                path: "unknown".to_string(),
                source: err,
            }
        }
    }
}

impl From<reqwest::Error> for SpandxError {
    fn from(err: reqwest::Error) -> Self {
        let url = err.url().map(|u| u.to_string()).unwrap_or_else(|| "unknown".to_string());
        
        if err.is_timeout() {
            Self::RequestTimeout { url, timeout_ms: 30000 } // Default timeout
        } else if err.is_status() {
            let status = err.status().map(|s| s.as_u16()).unwrap_or(0);
            Self::HttpError { 
                status, 
                url, 
                message: err.to_string() 
            }
        } else {
            Self::NetworkError {
                method: "unknown".to_string(),
                url,
                source: err,
            }
        }
    }
}

impl From<git2::Error> for SpandxError {
    fn from(err: git2::Error) -> Self {
        Self::GitError {
            operation: "unknown".to_string(),
            repository: "unknown".to_string(),
            source: err,
        }
    }
}

impl From<serde_json::Error> for SpandxError {
    fn from(err: serde_json::Error) -> Self {
        Self::SerializationError {
            message: "JSON serialization failed".to_string(),
            source: Box::new(err),
        }
    }
}

impl From<serde_yaml::Error> for SpandxError {
    fn from(err: serde_yaml::Error) -> Self {
        Self::SerializationError {
            message: "YAML serialization failed".to_string(),
            source: Box::new(err),
        }
    }
}

impl From<toml::de::Error> for SpandxError {
    fn from(err: toml::de::Error) -> Self {
        Self::SerializationError {
            message: "TOML deserialization failed".to_string(),
            source: Box::new(err),
        }
    }
}

impl From<csv::Error> for SpandxError {
    fn from(err: csv::Error) -> Self {
        Self::SerializationError {
            message: "CSV parsing failed".to_string(),
            source: Box::new(err),
        }
    }
}

impl From<anyhow::Error> for SpandxError {
    fn from(err: anyhow::Error) -> Self {
        Self::InternalError {
            message: err.to_string(),
        }
    }
}

impl From<std::string::FromUtf8Error> for SpandxError {
    fn from(err: std::string::FromUtf8Error) -> Self {
        Self::SerializationError {
            message: "UTF-8 conversion failed".to_string(),
            source: Box::new(err),
        }
    }
}

impl From<walkdir::Error> for SpandxError {
    fn from(err: walkdir::Error) -> Self {
        Self::FileSystemError {
            operation: "directory walk".to_string(),
            path: err.path().map(|p| p.display().to_string()).unwrap_or_else(|| "unknown".to_string()),
            source: std::io::Error::new(std::io::ErrorKind::Other, err),
        }
    }
}

impl From<camino::FromPathBufError> for SpandxError {
    fn from(err: camino::FromPathBufError) -> Self {
        Self::ValidationError {
            field: "path".to_string(),
            reason: format!("Invalid UTF-8 path: {}", err),
        }
    }
}

impl From<indicatif::style::TemplateError> for SpandxError {
    fn from(err: indicatif::style::TemplateError) -> Self {
        Self::InternalError {
            message: format!("Progress bar template error: {}", err),
        }
    }
}

/// Convenience macro for creating SpandxError with context
#[macro_export]
macro_rules! spandx_error {
    ($variant:ident, $($field:ident = $value:expr),* $(,)?) => {
        $crate::error::SpandxError::$variant {
            $($field: $value.into(),)*
        }
    };
}

/// Convenience macro for early return with SpandxError
#[macro_export]
macro_rules! bail {
    ($($arg:tt)*) => {
        return Err($crate::error::SpandxError::InternalError {
            message: format!($($arg)*),
        });
    };
}

/// Convenience macro for ensuring conditions
#[macro_export]
macro_rules! ensure {
    ($cond:expr, $($arg:tt)*) => {
        if !$cond {
            $crate::bail!($($arg)*);
        }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_categories() {
        let error = SpandxError::dependency_parse("test error");
        assert_eq!(error.category(), ErrorCategory::Parse);
        
        let error = SpandxError::file_system("read", "/test/path", std::io::Error::from(std::io::ErrorKind::NotFound));
        assert_eq!(error.category(), ErrorCategory::FileSystem);
        
        let error = SpandxError::cache("rebuild index");
        assert_eq!(error.category(), ErrorCategory::Cache);
    }
    
    #[test]
    fn test_retriable_errors() {
        // Test with a timeout error (retriable)
        let error = SpandxError::RequestTimeout {
            url: "https://example.com".to_string(),
            timeout_ms: 30000,
        };
        assert!(error.is_retriable());
        
        let error = SpandxError::FileNotFound { 
            path: "/test/path".to_string() 
        };
        assert!(!error.is_retriable());
    }
    
    #[test]
    fn test_user_messages() {
        let error = SpandxError::PackageNotFound {
            package: "react".to_string(),
            version: "18.0.0".to_string(),
            registry: "npm".to_string(),
        };
        assert_eq!(error.user_message(), "Package react@18.0.0 not found in npm");
    }
    
    #[test]
    fn test_error_constructors() {
        let error = SpandxError::validation("version", "must be semver");
        match error {
            SpandxError::ValidationError { field, reason } => {
                assert_eq!(field, "version");
                assert_eq!(reason, "must be semver");
            }
            _ => panic!("Wrong error type"),
        }
    }
}