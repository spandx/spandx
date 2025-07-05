use async_trait::async_trait;
use anyhow::Result;
use serde_json;

use super::OutputFormatter;
use crate::core::DependencyCollection;

pub struct JsonFormatter;

impl JsonFormatter {
    pub fn new() -> Self {
        Self
    }
}

impl Default for JsonFormatter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl OutputFormatter for JsonFormatter {
    async fn format(&self, dependencies: &DependencyCollection) -> Result<()> {
        // Output as line-delimited JSON (one JSON object per line)
        for dep in dependencies.iter() {
            let json = serde_json::to_string(dep)?;
            println!("{}", json);
        }

        Ok(())
    }

    fn name(&self) -> &'static str {
        "json"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{Dependency, DependencyCollection};

    #[tokio::test]
    async fn test_json_formatter_empty() {
        let formatter = JsonFormatter::new();
        let dependencies = DependencyCollection::new();
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_json_formatter_with_dependencies() {
        let formatter = JsonFormatter::new();
        let mut dependencies = DependencyCollection::new();
        
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string())
            .with_license("MIT".to_string());
        dependencies.add(dep);
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_formatter_name() {
        let formatter = JsonFormatter::new();
        assert_eq!(formatter.name(), "json");
    }
}