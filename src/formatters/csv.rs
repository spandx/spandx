use async_trait::async_trait;
use anyhow::Result;
use csv::WriterBuilder;
use std::io;

use super::OutputFormatter;
use crate::core::DependencyCollection;

pub struct CsvFormatter;

impl CsvFormatter {
    pub fn new() -> Self {
        Self
    }
}

impl Default for CsvFormatter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl OutputFormatter for CsvFormatter {
    async fn format(&self, dependencies: &DependencyCollection) -> Result<()> {
        let mut writer = WriterBuilder::new()
            .has_headers(true)
            .from_writer(io::stdout());

        // Write header
        writer.write_record(&["Name", "Version", "Licenses", "Location"])?;

        // Write dependencies
        for dep in dependencies.iter() {
            writer.write_record(&[
                &dep.name,
                &dep.version,
                &dep.license_display(),
                &dep.location.to_string(),
            ])?;
        }

        writer.flush()?;
        Ok(())
    }

    fn name(&self) -> &'static str {
        "csv"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{Dependency, DependencyCollection};

    #[tokio::test]
    async fn test_csv_formatter_empty() {
        let formatter = CsvFormatter::new();
        let dependencies = DependencyCollection::new();
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_csv_formatter_with_dependencies() {
        let formatter = CsvFormatter::new();
        let mut dependencies = DependencyCollection::new();
        
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string())
            .with_license("MIT".to_string());
        dependencies.add(dep);
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_formatter_name() {
        let formatter = CsvFormatter::new();
        assert_eq!(formatter.name(), "csv");
    }
}