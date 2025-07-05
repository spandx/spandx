use crate::error::{SpandxError, SpandxResult};
use camino::{Utf8Path, Utf8PathBuf};
use indicatif::{ProgressBar, ProgressStyle};
use tracing::{debug, info, warn};
use std::sync::Arc;
use tokio::sync::Mutex;

use crate::cli::args::OutputFormat;
use crate::core::{DependencyCollection, ParserRegistry, PackageManager};
use crate::formatters::FormatterRegistry;
use crate::parsers::ruby::GemfileLockParser;
use crate::gateway::{HttpClient, GatewayRegistry};
use crate::gateway::registries::RubyGemsGateway;
use crate::cache::CacheManager;

pub struct ScanCommand {
    pub path: Utf8PathBuf,
    pub recursive: bool,
    pub airgap: bool,
    pub format: OutputFormat,
    pub pull: bool,
}

impl ScanCommand {
    pub fn new(
        path: Utf8PathBuf,
        recursive: bool,
        airgap: bool,
        format: OutputFormat,
        pull: bool,
    ) -> Self {
        Self {
            path,
            recursive,
            airgap,
            format,
            pull,
        }
    }

    pub async fn execute(&self) -> SpandxResult<()> {
        info!("Starting scan of: {}", self.path);

        // Set airgap mode globally
        crate::set_airgap_mode(self.airgap);

        // Pull cache if requested
        if self.pull {
            info!("Pulling latest cache...");
            let pull_command = super::PullCommand::new();
            if let Err(e) = pull_command.execute().await {
                warn!("Failed to pull cache: {}", e);
            }
        }

        // Initialize cache manager
        let cache_manager = Arc::new(Mutex::new(CacheManager::new().await?));

        // Initialize gateway registry
        let http_client = Arc::new(HttpClient::new());
        let mut gateway_registry = GatewayRegistry::new(http_client.clone());
        self.register_gateways(&mut gateway_registry);

        // Initialize parser registry
        let mut parser_registry = ParserRegistry::new();
        self.register_parsers(&mut parser_registry);

        // Find files to scan
        let files = self.find_scannable_files(&parser_registry)?;
        
        if files.is_empty() {
            warn!("No scannable files found");
            return Ok(());
        }

        info!("Found {} files to scan", files.len());

        // Scan files with progress bar
        let mut dependencies = self.scan_files(&parser_registry, files).await?;

        // Enrich dependencies with license information
        self.enrich_dependencies(&mut dependencies, &gateway_registry, &cache_manager).await?;

        // Format and output results
        self.output_results(dependencies).await?;

        Ok(())
    }

    fn register_gateways(&self, registry: &mut GatewayRegistry) {
        // Register RubyGems gateway
        registry.register(RubyGemsGateway::new(registry.http_client()));
        
        // Note: Other gateways will be registered here as they're implemented
        // registry.register(NpmGateway::new(registry.http_client()));
        // registry.register(PypiGateway::new(registry.http_client()));
        // registry.register(NugetGateway::new(registry.http_client()));
        // registry.register(MavenGateway::new(registry.http_client()));
        // registry.register(PackagistGateway::new(registry.http_client()));
        
        debug!("Registered {} gateways", registry.len());
    }

    fn register_parsers(&self, registry: &mut ParserRegistry) {
        // Register Ruby parser
        registry.register(GemfileLockParser::new());
        
        // Note: These will be implemented in separate modules
        // registry.register(JavaScriptParser::new());
        // registry.register(PythonParser::new());
        // registry.register(DotnetParser::new());
        // registry.register(JavaParser::new());
        // registry.register(PhpParser::new());
        // registry.register(TerraformParser::new());
        // registry.register(OsParser::new());
        
        debug!("Registered {} parsers", registry.parsers().len());
    }

    fn find_scannable_files(&self, registry: &ParserRegistry) -> SpandxResult<Vec<Utf8PathBuf>> {
        let mut files = Vec::new();

        if self.path.is_file() {
            if registry.find_parser(&self.path).is_some() {
                files.push(self.path.clone());
            }
        } else if self.path.is_dir() {
            files.extend(self.find_files_in_directory(&self.path, registry)?);
        } else {
            return Err(SpandxError::FileNotFound {
                path: self.path.to_string()
            });
        }

        Ok(files)
    }

    fn find_files_in_directory(
        &self,
        dir: &Utf8Path,
        registry: &ParserRegistry,
    ) -> SpandxResult<Vec<Utf8PathBuf>> {
        use walkdir::WalkDir;
        
        let mut files = Vec::new();
        let walker = if self.recursive {
            WalkDir::new(dir)
        } else {
            WalkDir::new(dir).max_depth(1)
        };

        for entry in walker {
            let entry = entry?;
            let path = Utf8PathBuf::try_from(entry.path().to_path_buf())?;
            
            if path.is_file() && registry.find_parser(&path).is_some() {
                files.push(path);
            }
        }

        Ok(files)
    }

    async fn scan_files(
        &self,
        registry: &ParserRegistry,
        files: Vec<Utf8PathBuf>,
    ) -> SpandxResult<DependencyCollection> {
        let progress_bar = ProgressBar::new(files.len() as u64);
        progress_bar.set_style(
            ProgressStyle::default_bar()
                .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} {msg}")?
                .progress_chars("#>-"),
        );

        let mut all_dependencies = DependencyCollection::new();

        for file in files {
            progress_bar.set_message(format!("Scanning {}", file.file_name().unwrap_or("")));
            
            match registry.parse_file(&file).await {
                Ok(dependencies) => {
                    info!("Found {} dependencies in {}", dependencies.len(), file);
                    
                    // Set location for all dependencies
                    for dep in dependencies.iter().cloned() {
                        all_dependencies.add(dep.with_location(file.clone()));
                    }
                }
                Err(e) => {
                    warn!("Failed to parse {}: {}", file, e);
                }
            }

            progress_bar.inc(1);
        }

        progress_bar.finish_with_message("Scan complete");
        
        // Sort dependencies by name for consistent output
        all_dependencies.sort_by_name();

        Ok(all_dependencies)
    }

    async fn enrich_dependencies(
        &self,
        dependencies: &mut DependencyCollection,
        gateway_registry: &GatewayRegistry,
        cache_manager: &Arc<Mutex<CacheManager>>,
    ) -> SpandxResult<()> {
        let deps: Vec<_> = dependencies.iter().cloned().collect();
        if deps.is_empty() {
            return Ok(());
        }

        info!("Enriching {} dependencies with license information", deps.len());

        let progress_bar = ProgressBar::new(deps.len() as u64);
        progress_bar.set_style(
            ProgressStyle::default_bar()
                .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} Enriching licenses...")
                .map_err(|e| SpandxError::InvalidArguments {
                    message: format!("Failed to create progress style: {}", e)
                })?
                .progress_chars("#>-"),
        );

        let mut enriched_deps = Vec::new();

        for dep in deps {
            progress_bar.set_message(format!("Processing {}", dep.name));

            let mut enriched_dep = dep.clone();

            // Get package manager from source
            let package_manager = if let Some(source) = &dep.source {
                PackageManager::from_source(source).to_source_string().to_string()
            } else {
                "unknown".to_string()
            };

            // First try to get licenses from cache (for airgap mode or performance)
            {
                let mut cache_mgr = cache_manager.lock().await;
                if let Ok(Some(cached_licenses)) = cache_mgr.get_licenses(&dep.name, &dep.version, &package_manager).await {
                    if !cached_licenses.is_empty() {
                        debug!("Found cached licenses for {}@{}: {:?}", dep.name, dep.version, cached_licenses);
                        enriched_dep = enriched_dep.with_licenses(cached_licenses);
                    }
                }
            }

            // If no cached licenses and not in airgap mode, try gateway
            if enriched_dep.licenses.is_empty() && !self.airgap {
                if let Ok(gateway_licenses) = gateway_registry.get_licenses(&dep).await {
                    if !gateway_licenses.is_empty() {
                        debug!("Found gateway licenses for {}@{}: {:?}", dep.name, dep.version, gateway_licenses);
                        enriched_dep = enriched_dep.with_licenses(gateway_licenses.clone());
                        
                        // Cache the discovered licenses for future use
                        let mut cache_mgr = cache_manager.lock().await;
                        if let Err(e) = cache_mgr.set_licenses(&dep.name, &dep.version, &package_manager, gateway_licenses).await {
                            warn!("Failed to cache licenses for {}@{}: {}", dep.name, dep.version, e);
                        }
                    }
                }
            }

            // If still no licenses found, mark as Unknown
            if enriched_dep.licenses.is_empty() {
                enriched_dep = enriched_dep.with_licenses(vec!["Unknown".to_string()]);
            }

            enriched_deps.push(enriched_dep);
            progress_bar.inc(1);
        }

        progress_bar.finish_with_message("License enrichment complete");

        // Create a new collection with enriched dependencies
        *dependencies = DependencyCollection::from(enriched_deps);

        Ok(())
    }

    async fn output_results(&self, dependencies: DependencyCollection) -> SpandxResult<()> {
        let mut formatter_registry = FormatterRegistry::new();
        formatter_registry.register_all();

        let formatter = formatter_registry
            .get_formatter(&self.format.to_string())
            .ok_or_else(|| SpandxError::InvalidArguments {
                message: format!("Unknown output format: {}", self.format)
            })?;

        formatter.format(&dependencies).await?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    use std::fs;

    #[tokio::test]
    async fn test_scan_command_creation() {
        let cmd = ScanCommand::new(
            "test.lock".into(),
            true,
            false,
            OutputFormat::Json,
            false,
        );

        assert_eq!(cmd.path.as_str(), "test.lock");
        assert!(cmd.recursive);
        assert!(!cmd.airgap);
        assert!(matches!(cmd.format, OutputFormat::Json));
        assert!(!cmd.pull);
    }

    #[tokio::test]
    async fn test_find_scannable_files_empty_directory() {
        let temp_dir = TempDir::new().unwrap();
        let temp_path = Utf8PathBuf::try_from(temp_dir.path().to_path_buf()).unwrap();
        
        let cmd = ScanCommand::new(
            temp_path,
            false,
            false,
            OutputFormat::Table,
            false,
        );

        let registry = ParserRegistry::new();
        let files = cmd.find_scannable_files(&registry).unwrap();
        assert!(files.is_empty());
    }

    #[test]
    fn test_find_files_nonexistent_path() {
        let cmd = ScanCommand::new(
            "/nonexistent/path".into(),
            false,
            false,
            OutputFormat::Table,
            false,
        );

        let registry = ParserRegistry::new();
        let result = cmd.find_scannable_files(&registry);
        assert!(result.is_err());
    }
}