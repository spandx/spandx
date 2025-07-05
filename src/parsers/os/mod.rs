pub mod apk;
pub mod dpkg;

#[cfg(test)]
mod tests;

pub use apk::ApkParser;
pub use dpkg::DpkgParser;