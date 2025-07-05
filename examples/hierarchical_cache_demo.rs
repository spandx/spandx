//! Hierarchical Binary-Indexed Cache System Demo
//! 
//! This example demonstrates the multi-level cache hierarchy:
//! - L1: Fast in-memory LRU cache (configurable size)
//! - L2: Binary-indexed disk cache with 256 SHA1-based buckets
//! - L3: Remote package registry fallback (simulated)

use std::time::Instant;
use spandx::cache::Cache;
use camino::Utf8PathBuf;
use tempfile::TempDir;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("🔗 Hierarchical Binary-Indexed Cache System Demo");
    println!("================================================");
    
    // Initialize cache with small L1 cache for demonstration
    let temp_dir = TempDir::new()?;
    let cache_dir = Utf8PathBuf::from_path_buf(temp_dir.path().to_path_buf())
        .map_err(|e| format!("Failed to convert path: {:?}", e))?;
    let mut cache = Cache::with_memory_cache_size(cache_dir, 3); // Only 3 entries in L1
    
    println!("📊 Initial cache state:");
    print_cache_stats(&cache);
    
    // Simulate populating cache with package license data
    let packages = [
        ("rails", "7.0.0", "rubygems", vec!["MIT".to_string()]),
        ("express", "4.18.0", "npm", vec!["MIT".to_string()]),
        ("django", "4.2.0", "pypi", vec!["BSD-3-Clause".to_string()]),
        ("spring-boot", "3.0.0", "maven", vec!["Apache-2.0".to_string()]),
        ("react", "18.0.0", "npm", vec!["MIT".to_string()]),
        ("numpy", "1.24.0", "pypi", vec!["BSD-3-Clause".to_string()]),
    ];
    
    println!("\n🔄 Populating cache with {} packages...", packages.len());
    for (name, version, pm, licenses) in &packages {
        cache.set_licenses(name, version, pm, licenses.clone()).await?;
        println!("  ✅ Cached {}@{} ({}): {:?}", name, version, pm, licenses);
    }
    
    println!("\n📊 Cache state after population:");
    print_cache_stats(&cache);
    
    // Demonstrate L1 cache hits (fastest)
    println!("\n⚡ Testing L1 cache hits (should be very fast):");
    for (name, version, pm, expected) in packages.iter().take(3) {
        let start = Instant::now();
        let result = cache.get_licenses(name, version, pm).await?;
        let duration = start.elapsed();
        
        match result {
            Some(licenses) => {
                println!("  🎯 L1 HIT: {}@{} -> {:?} ({:.2}μs)", 
                    name, version, licenses, duration.as_micros());
                assert_eq!(licenses, *expected);
            }
            None => println!("  ❌ MISS: {}@{}", name, version),
        }
    }
    
    // Clear L1 cache to test L2 fallback
    println!("\n🧹 Clearing L1 cache to demonstrate L2 fallback...");
    cache.clear_memory_cache();
    print_cache_stats(&cache);
    
    // Demonstrate L2 cache hits (slower but still fast)
    println!("\n💾 Testing L2 cache hits (binary-indexed disk):");
    for (name, version, pm, expected) in &packages {
        let start = Instant::now();
        let result = cache.get_licenses(name, version, pm).await?;
        let duration = start.elapsed();
        
        match result {
            Some(licenses) => {
                println!("  🎯 L2 HIT: {}@{} -> {:?} ({:.2}μs)", 
                    name, version, licenses, duration.as_micros());
                assert_eq!(licenses, *expected);
            }
            None => println!("  ❌ MISS: {}@{}", name, version),
        }
    }
    
    println!("\n📊 Final cache state (L2 entries promoted to L1):");
    print_cache_stats(&cache);
    
    // Demonstrate cache miss (would trigger L3 fallback in real system)
    println!("\n🔍 Testing cache miss (would trigger remote registry lookup):");
    let start = Instant::now();
    let result = cache.get_licenses("nonexistent", "1.0.0", "npm").await?;
    let duration = start.elapsed();
    
    match result {
        Some(licenses) => println!("  🎯 Unexpected hit: {:?}", licenses),
        None => println!("  ❌ MISS: nonexistent@1.0.0 -> would fetch from registry ({:.2}μs)", 
            duration.as_micros()),
    }
    
    // Demonstrate bucket distribution
    println!("\n🗂️  Cache bucket distribution:");
    print_bucket_analysis(&packages);
    
    println!("\n✨ Demo complete! The hierarchical cache provides:");
    println!("   • L1: Ultra-fast memory access (μs latency)");
    println!("   • L2: Fast binary-indexed disk access (ms latency)");
    println!("   • L3: Remote registry fallback (s latency, not shown)");
    println!("   • Automatic promotion between levels");
    println!("   • LRU eviction in L1 memory cache");
    println!("   • SHA1-based bucketing for optimal distribution");
    
    Ok(())
}

fn print_cache_stats(cache: &Cache) {
    let stats = cache.memory_cache_stats();
    println!("  L1 Memory Cache: {}/{} entries ({:.1}% utilization, {} remaining)",
        stats.entries, 
        stats.max_entries,
        stats.utilization() * 100.0,
        stats.remaining_capacity());
}

fn print_bucket_analysis(packages: &[(&str, &str, &str, Vec<String>)]) {
    use sha1::{Digest, Sha1};
    
    for (name, version, pm, _) in packages {
        let mut hasher = Sha1::new();
        hasher.update(name.as_bytes());
        let hash = hasher.finalize();
        let bucket = format!("{:02x}", hash[0]);
        
        println!("  📁 {}@{} ({}) -> bucket {} (hash: {:02x}{}...)",
            name, version, pm, bucket, hash[0], 
            hash.iter().skip(1).take(2).map(|b| format!("{:02x}", b)).collect::<String>());
    }
}