//! Performance Benchmarks for Spandx
//! 
//! These benchmarks measure the performance of critical components
//! to ensure the system meets performance requirements and to catch regressions.

use criterion::{black_box, criterion_group, criterion_main, Criterion, BenchmarkId};
use spandx::core::{Dependency, DependencyCollection, License};
use spandx::parsers::ruby::GemfileLockParser;
use spandx::parsers::javascript::PackageLockParser;
use spandx::spdx::{SpdxCatalogue, LicenseExpression};
use spandx::cache::Cache;
use spandx::core::license::calculate_similarity;
use camino::Utf8PathBuf;
use tempfile::TempDir;
use std::fs;
use tokio::runtime::Runtime;

/// Benchmark dependency creation and manipulation
fn benchmark_dependency_operations(c: &mut Criterion) {
    let mut group = c.benchmark_group("dependency_operations");
    
    // Benchmark dependency creation
    group.bench_function("create_dependency", |b| {
        b.iter(|| {
            let dep = Dependency::new(
                black_box("test-package"), 
                black_box("1.0.0")
            );
            black_box(dep)
        })
    });
    
    // Benchmark dependency collection operations
    let deps: Vec<_> = (0..1000).map(|i| {
        Dependency::new(&format!("package-{}", i), "1.0.0")
    }).collect();
    
    group.bench_function("add_1000_dependencies", |b| {
        b.iter(|| {
            let mut collection = DependencyCollection::new();
            for dep in &deps {
                collection.add(black_box(dep.clone()));
            }
            black_box(collection)
        })
    });
    
    group.bench_function("sort_1000_dependencies", |b| {
        let mut collection = DependencyCollection::new();
        for dep in &deps {
            collection.add(dep.clone());
        }
        
        b.iter(|| {
            let mut coll = collection.clone();
            coll.sort_by_name();
            black_box(coll)
        })
    });
    
    group.finish();
}

/// Benchmark SPDX license operations
fn benchmark_spdx_operations(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let mut group = c.benchmark_group("spdx_operations");
    
    // Get catalogue once for reuse
    let catalogue = rt.block_on(async {
        SpdxCatalogue::fetch().await.unwrap()
    });
    
    group.bench_function("parse_simple_expression", |b| {
        b.iter(|| {
            let expr = LicenseExpression::parse(black_box("MIT"));
            black_box(expr)
        })
    });
    
    group.bench_function("parse_complex_expression", |b| {
        b.iter(|| {
            let expr = LicenseExpression::parse(
                black_box("(MIT OR Apache-2.0) AND BSD-3-Clause")
            );
            black_box(expr)
        })
    });
    
    group.bench_function("lookup_license", |b| {
        b.iter(|| {
            let license = catalogue.get_license(black_box("MIT"));
            black_box(license)
        })
    });
    
    group.bench_function("find_similar_licenses", |b| {
        b.iter(|| {
            let similar = catalogue.find_similar_licenses(
                black_box("MIT License\n\nPermission is hereby granted..."), 
                black_box(0.8)
            );
            black_box(similar)
        })
    });
    
    group.finish();
}

/// Benchmark license similarity calculations
fn benchmark_license_similarity(c: &mut Criterion) {
    let mut group = c.benchmark_group("license_similarity");
    
    let mit_text = include_str!("../test_data/licenses/mit.txt");
    let apache_text = include_str!("../test_data/licenses/apache-2.0.txt");
    let gpl_text = include_str!("../test_data/licenses/gpl-3.0.txt");
    
    // Different text sizes
    let texts = [
        ("short", "MIT"),
        ("medium", &mit_text[..200]),
        ("long", mit_text),
        ("very_long", apache_text),
    ];
    
    for (size_name, text1) in &texts {
        for (_, text2) in &texts {
            group.bench_with_input(
                BenchmarkId::new("similarity", format!("{}_{}", size_name, size_name)),
                &(text1, text2),
                |b, (t1, t2)| {
                    b.iter(|| {
                        let sim = calculate_similarity(black_box(t1), black_box(t2));
                        black_box(sim)
                    })
                }
            );
        }
    }
    
    group.finish();
}

/// Benchmark file parsing operations
fn benchmark_file_parsing(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let mut group = c.benchmark_group("file_parsing");
    
    // Create test files
    let temp_dir = TempDir::new().unwrap();
    
    // Small Gemfile.lock
    let small_gemfile = temp_dir.path().join("small_Gemfile.lock");
    fs::write(&small_gemfile, create_gemfile_content(10)).unwrap();
    
    // Large Gemfile.lock
    let large_gemfile = temp_dir.path().join("large_Gemfile.lock");
    fs::write(&large_gemfile, create_gemfile_content(100)).unwrap();
    
    // Small package-lock.json
    let small_package_lock = temp_dir.path().join("small_package-lock.json");
    fs::write(&small_package_lock, create_package_lock_content(10)).unwrap();
    
    // Large package-lock.json
    let large_package_lock = temp_dir.path().join("large_package-lock.json");
    fs::write(&large_package_lock, create_package_lock_content(100)).unwrap();
    
    let ruby_parser = GemfileLockParser::new();
    let js_parser = PackageLockParser::new();
    
    group.bench_function("parse_small_gemfile", |b| {
        let path = Utf8PathBuf::try_from(small_gemfile.clone()).unwrap();
        b.to_async(&rt).iter(|| async {
            let deps = ruby_parser.parse_file(black_box(&path)).await;
            black_box(deps)
        })
    });
    
    group.bench_function("parse_large_gemfile", |b| {
        let path = Utf8PathBuf::try_from(large_gemfile.clone()).unwrap();
        b.to_async(&rt).iter(|| async {
            let deps = ruby_parser.parse_file(black_box(&path)).await;
            black_box(deps)
        })
    });
    
    group.bench_function("parse_small_package_lock", |b| {
        let path = Utf8PathBuf::try_from(small_package_lock.clone()).unwrap();
        b.to_async(&rt).iter(|| async {
            let deps = js_parser.parse_file(black_box(&path)).await;
            black_box(deps)
        })
    });
    
    group.bench_function("parse_large_package_lock", |b| {
        let path = Utf8PathBuf::try_from(large_package_lock.clone()).unwrap();
        b.to_async(&rt).iter(|| async {
            let deps = js_parser.parse_file(black_box(&path)).await;
            black_box(deps)
        })
    });
    
    group.finish();
}

/// Benchmark cache operations
fn benchmark_cache_operations(c: &mut Criterion) {
    let rt = Runtime::new().unwrap();
    let mut group = c.benchmark_group("cache_operations");
    
    let temp_dir = TempDir::new().unwrap();
    let cache_dir = Utf8PathBuf::try_from(temp_dir.path().to_path_buf()).unwrap();
    
    let cache = rt.block_on(async {
        Cache::new(cache_dir).await.unwrap()
    });
    
    // Test data of different sizes
    let small_data: Vec<String> = (0..10).map(|i| format!("item-{}", i)).collect();
    let medium_data: Vec<String> = (0..100).map(|i| format!("item-{}", i)).collect();
    let large_data: Vec<String> = (0..1000).map(|i| format!("item-{}", i)).collect();
    
    group.bench_function("write_small_data", |b| {
        let mut cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.write(black_box("small_key"), black_box(&small_data)).await;
            black_box(result)
        })
    });
    
    group.bench_function("write_medium_data", |b| {
        let mut cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.write(black_box("medium_key"), black_box(&medium_data)).await;
            black_box(result)
        })
    });
    
    group.bench_function("write_large_data", |b| {
        let mut cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.write(black_box("large_key"), black_box(&large_data)).await;
            black_box(result)
        })
    });
    
    // Pre-populate cache for read benchmarks
    rt.block_on(async {
        let mut cache = cache.clone();
        cache.write("read_small", &small_data).await.unwrap();
        cache.write("read_medium", &medium_data).await.unwrap();
        cache.write("read_large", &large_data).await.unwrap();
    });
    
    group.bench_function("read_small_data", |b| {
        let cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.read::<Vec<String>>(black_box("read_small")).await;
            black_box(result)
        })
    });
    
    group.bench_function("read_medium_data", |b| {
        let cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.read::<Vec<String>>(black_box("read_medium")).await;
            black_box(result)
        })
    });
    
    group.bench_function("read_large_data", |b| {
        let cache = cache.clone();
        b.to_async(&rt).iter(|| async {
            let result = cache.read::<Vec<String>>(black_box("read_large")).await;
            black_box(result)
        })
    });
    
    group.finish();
}

/// Helper function to create Gemfile.lock content with specified number of gems
fn create_gemfile_content(num_gems: usize) -> String {
    let mut content = String::from("GEM\n  remote: https://rubygems.org/\n  specs:\n");
    
    for i in 0..num_gems {
        content.push_str(&format!("    gem-{} (1.{}.0)\n", i, i));
    }
    
    content.push_str("\nPLATFORMS\n  ruby\n\nDEPENDENCIES\n");
    
    for i in 0..num_gems {
        content.push_str(&format!("  gem-{}\n", i));
    }
    
    content.push_str("\nBUNDLED WITH\n   2.3.7\n");
    content
}

/// Helper function to create package-lock.json content with specified number of packages
fn create_package_lock_content(num_packages: usize) -> String {
    let mut content = String::from(r#"{"name": "test", "version": "1.0.0", "lockfileVersion": 2, "packages": {"#);
    
    content.push_str(r#""": {"version": "1.0.0"},"#);
    
    for i in 0..num_packages {
        content.push_str(&format!(r#""node_modules/package-{}": {{"version": "1.{}.0"}},"#, i, i));
    }
    
    // Remove trailing comma
    content.pop();
    
    content.push_str(r#"}, "dependencies": {"#);
    
    for i in 0..num_packages {
        content.push_str(&format!(r#""package-{}": {{"version": "1.{}.0"}},"#, i, i));
    }
    
    // Remove trailing comma
    content.pop();
    
    content.push_str("}}");
    content
}

criterion_group!(
    benches,
    benchmark_dependency_operations,
    benchmark_spdx_operations,
    benchmark_license_similarity,
    benchmark_file_parsing,
    benchmark_cache_operations
);

criterion_main!(benches);