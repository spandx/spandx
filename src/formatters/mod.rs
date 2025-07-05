pub mod table;
pub mod csv;
pub mod json;

use async_trait::async_trait;
use std::collections::HashMap;
use anyhow::Result;

use crate::core::DependencyCollection;

#[async_trait]
pub trait OutputFormatter: Send + Sync {
    async fn format(&self, dependencies: &DependencyCollection) -> Result<()>;
    fn name(&self) -> &'static str;
}

pub struct FormatterRegistry {
    formatters: HashMap<String, Box<dyn OutputFormatter>>,
}

impl FormatterRegistry {
    pub fn new() -> Self {
        Self {
            formatters: HashMap::new(),
        }
    }

    pub fn register<F: OutputFormatter + 'static>(&mut self, formatter: F) {
        self.formatters.insert(formatter.name().to_string(), Box::new(formatter));
    }

    pub fn register_all(&mut self) {
        self.register(table::TableFormatter::new());
        self.register(csv::CsvFormatter::new());
        self.register(json::JsonFormatter::new());
    }

    pub fn get_formatter(&self, name: &str) -> Option<&dyn OutputFormatter> {
        self.formatters.get(name).map(|f| f.as_ref())
    }

    pub fn supported_formats(&self) -> Vec<&str> {
        self.formatters.keys().map(|s| s.as_str()).collect()
    }
}

impl Default for FormatterRegistry {
    fn default() -> Self {
        let mut registry = Self::new();
        registry.register_all();
        registry
    }
}