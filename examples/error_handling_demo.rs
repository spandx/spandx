//! Enhanced Error Handling System Demo
//! 
//! This example demonstrates the comprehensive error handling system:
//! - Structured error types with categories
//! - User-friendly error messages
//! - Retry logic for retriable errors
//! - Proper error context and debugging info

use spandx::error::{SpandxError, SpandxResult, ErrorCategory};
use std::collections::HashMap;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🚨 Enhanced Error Handling System Demo");
    println!("=====================================");
    
    // Demonstrate different error categories and user messages
    let errors = vec![
        // File system errors
        SpandxError::FileNotFound { 
            path: "/nonexistent/Gemfile.lock".to_string() 
        },
        SpandxError::PermissionDenied { 
            path: "/etc/shadow".to_string() 
        },
        
        // Network errors
        SpandxError::NetworkError {
            method: "GET".to_string(),
            url: "https://api.github.com/nonexistent".to_string(),
            source: reqwest::Error::from(reqwest::Client::new().get("http://invalid").send().await.err().unwrap()),
        },
        SpandxError::RequestTimeout {
            url: "https://slow-api.example.com".to_string(),
            timeout_ms: 30000,
        },
        
        // Package management errors
        SpandxError::PackageNotFound {
            package: "nonexistent-package".to_string(),
            version: "1.0.0".to_string(),
            registry: "npm".to_string(),
        },
        SpandxError::LicenseDetectionError {
            package: "some-package".to_string(),
            version: "2.0.0".to_string(),
            reason: "No license information found in package metadata".to_string(),
        },
        
        // Configuration errors
        SpandxError::ConfigError {
            message: "Invalid SPDX cache directory".to_string(),
            source: None,
        },
        SpandxError::InvalidConfigValue {
            key: "cache.max_size".to_string(),
            value: "not-a-number".to_string(),
        },
        
        // Parse errors
        SpandxError::ParseError {
            file_type: "package-lock.json".to_string(),
            file_path: "/path/to/package-lock.json".to_string(),
            source: Box::new(serde_json::Error::io(std::io::Error::new(std::io::ErrorKind::InvalidData, "test"))),
        },
        SpandxError::InvalidLicenseExpression {
            expression: "MIT AND AND Apache-2.0".to_string(),
            source: None,
        },
        
        // Git errors
        SpandxError::GitError {
            operation: "clone".to_string(),
            repository: "https://github.com/nonexistent/repo.git".to_string(),
            source: git2::Error::from_str("repository not found"),
        },
        
        // Cache errors
        SpandxError::CacheCorruption {
            details: "Binary index file has invalid magic number".to_string(),
        },
        SpandxError::CacheCapacityError {
            current_size: 10000,
            max_size: 5000,
        },
        
        // CLI errors
        SpandxError::InvalidArguments {
            message: "Cannot specify both --airgap and --pull flags".to_string(),
        },
        SpandxError::NotImplemented {
            feature: "Docker container scanning".to_string(),
        },
    ];
    
    // Demonstrate error categorization and user messages
    println!("\n📋 Error Categories and User Messages:");
    println!("-------------------------------------");
    
    let mut category_counts: HashMap<ErrorCategory, usize> = HashMap::new();
    
    for (i, error) in errors.iter().enumerate() {
        let category = error.category();
        *category_counts.entry(category).or_insert(0) += 1;
        
        println!("\n{}. Error Category: {} | Retriable: {}", 
            i + 1, 
            category, 
            if error.is_retriable() { "✓" } else { "✗" }
        );
        println!("   User Message: {}", error.user_message());
        
        if error.is_retriable() {
            if let Some(delay_ms) = error.retry_delay_ms() {
                println!("   Suggested retry delay: {}ms", delay_ms);
            }
        }
    }
    
    // Show category statistics
    println!("\n📊 Error Category Statistics:");
    println!("----------------------------");
    for (category, count) in &category_counts {
        println!("  {}: {} errors", category, count);
    }
    
    // Demonstrate error context and chaining
    println!("\n🔗 Error Context and Chaining:");
    println!("------------------------------");
    
    let chained_error = demonstrate_error_chain().await;
    match chained_error {
        Err(e) => {
            println!("Main error: {}", e.user_message());
            println!("Full error: {:?}", e);
            println!("Category: {}", e.category());
        }
        Ok(_) => println!("No error occurred"),
    }
    
    // Demonstrate retry logic
    println!("\n🔄 Retry Logic Demonstration:");
    println!("-----------------------------");
    
    let mut attempt = 1;
    let max_attempts = 3;
    
    loop {
        println!("Attempt {}/{}", attempt, max_attempts);
        
        match simulate_network_operation(attempt).await {
            Ok(result) => {
                println!("✅ Success: {}", result);
                break;
            }
            Err(e) => {
                println!("❌ Error: {}", e.user_message());
                
                if e.is_retriable() && attempt < max_attempts {
                    if let Some(delay_ms) = e.retry_delay_ms() {
                        println!("   Retrying in {}ms...", delay_ms);
                        tokio::time::sleep(tokio::time::Duration::from_millis(delay_ms)).await;
                    }
                    attempt += 1;
                } else {
                    println!("   Maximum attempts reached or error not retriable");
                    break;
                }
            }
        }
    }
    
    // Demonstrate error conversion and convenience functions
    println!("\n🛠️  Error Conversion Examples:");
    println!("-----------------------------");
    
    // From standard library errors
    let io_error = std::io::Error::new(std::io::ErrorKind::NotFound, "File not found");
    let spandx_error: SpandxError = io_error.into();
    println!("IO Error → SpandxError: {}", spandx_error.user_message());
    
    // Using convenience constructors
    let validation_error = SpandxError::validation("version", "must be valid semver");
    println!("Validation Error: {}", validation_error.user_message());
    
    let license_error = SpandxError::license_detection("react", "18.0.0", "SPDX expression parsing failed");
    println!("License Error: {}", license_error.user_message());
    
    println!("\n✨ Error handling system provides:");
    println!("  • Structured error types with rich context");
    println!("  • User-friendly error messages");
    println!("  • Categorization for metrics and handling");
    println!("  • Retry logic for transient failures");
    println!("  • Proper error chaining and debugging info");
    println!("  • Consistent error handling across all modules");
    
    Ok(())
}

/// Simulate a complex operation that can fail with chained errors
async fn demonstrate_error_chain() -> SpandxResult<String> {
    // Simulate parsing a file that leads to a license detection error
    parse_package_file().await
        .map_err(|e| SpandxError::DependencyParseError {
            message: "Failed to extract dependencies".to_string(),
            source: Some(Box::new(e)),
        })?;
    
    Ok("Successfully processed package file".to_string())
}

async fn parse_package_file() -> SpandxResult<Vec<String>> {
    // Simulate a file parsing error
    Err(SpandxError::ParseError {
        file_type: "package.json".to_string(),
        file_path: "/app/package.json".to_string(),
        source: Box::new(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            "Invalid JSON syntax at line 15"
        )),
    })
}

/// Simulate a network operation that succeeds after retries
async fn simulate_network_operation(attempt: u32) -> SpandxResult<String> {
    match attempt {
        1 => Err(SpandxError::RequestTimeout {
            url: "https://api.example.com/packages".to_string(),
            timeout_ms: 5000,
        }),
        2 => Err(SpandxError::HttpError {
            status: 503,
            url: "https://api.example.com/packages".to_string(),
            message: "Service temporarily unavailable".to_string(),
        }),
        3 => Ok("Successfully fetched package data".to_string()),
        _ => Err(SpandxError::InternalError {
            message: "Unexpected attempt number".to_string(),
        }),
    }
}