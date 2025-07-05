pub mod lock_file;

#[cfg(test)]
mod tests;

pub use lock_file::TerraformLockParser;