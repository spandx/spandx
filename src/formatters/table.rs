use async_trait::async_trait;
use anyhow::Result;
use tabled::{Table, Tabled};

use super::OutputFormatter;
use crate::core::DependencyCollection;

pub struct TableFormatter;

impl TableFormatter {
    pub fn new() -> Self {
        Self
    }
}

impl Default for TableFormatter {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl OutputFormatter for TableFormatter {
    async fn format(&self, dependencies: &DependencyCollection) -> Result<()> {
        if dependencies.is_empty() {
            println!("No dependencies found");
            return Ok(());
        }

        let rows: Vec<DependencyRow> = dependencies
            .iter()
            .map(|dep| DependencyRow {
                name: dep.name.clone(),
                version: dep.version.clone(),
                licenses: dep.license_display(),
                location: dep.location.to_string(),
            })
            .collect();

        let table = Table::new(rows);
        println!("{}", table);

        Ok(())
    }

    fn name(&self) -> &'static str {
        "table"
    }
}

#[derive(Tabled)]
struct DependencyRow {
    #[tabled(rename = "Name")]
    name: String,
    #[tabled(rename = "Version")]
    version: String,
    #[tabled(rename = "Licenses")]
    licenses: String,
    #[tabled(rename = "Location")]
    location: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{Dependency, DependencyCollection};

    #[tokio::test]
    async fn test_table_formatter_empty() {
        let formatter = TableFormatter::new();
        let dependencies = DependencyCollection::new();
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_table_formatter_with_dependencies() {
        let formatter = TableFormatter::new();
        let mut dependencies = DependencyCollection::new();
        
        let dep = Dependency::new("test".to_string(), "1.0.0".to_string())
            .with_license("MIT".to_string());
        dependencies.add(dep);
        
        let result = formatter.format(&dependencies).await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_formatter_name() {
        let formatter = TableFormatter::new();
        assert_eq!(formatter.name(), "table");
    }
}