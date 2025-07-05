use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum PackageManager {
    RubyGems,
    Npm,
    Yarn,
    Python,
    Pip,
    Pipenv,
    Poetry,
    Maven,
    Gradle,
    NuGet,
    Composer,
    Go,
    Cargo,
    CocoaPods,
    Carthage,
    SwiftPM,
    Conda,
    Terraform,
    Docker,
    Alpine,
    Debian,
    Unknown(String),
}

impl PackageManager {
    pub fn from_source(source: &str) -> Self {
        match source.to_lowercase().as_str() {
            "rubygems" | "ruby" | "gem" => Self::RubyGems,
            "npm" => Self::Npm,
            "yarn" => Self::Yarn,
            "python" | "pypi" => Self::Python,
            "pip" => Self::Pip,
            "pipenv" => Self::Pipenv,
            "poetry" => Self::Poetry,
            "maven" => Self::Maven,
            "gradle" => Self::Gradle,
            "nuget" | ".net" | "dotnet" => Self::NuGet,
            "composer" | "packagist" | "php" => Self::Composer,
            "go" | "golang" => Self::Go,
            "cargo" | "rust" => Self::Cargo,
            "cocoapods" => Self::CocoaPods,
            "carthage" => Self::Carthage,
            "swift" | "spm" => Self::SwiftPM,
            "conda" => Self::Conda,
            "terraform" => Self::Terraform,
            "docker" => Self::Docker,
            "apk" | "alpine" => Self::Alpine,
            "dpkg" | "debian" | "apt" => Self::Debian,
            _ => Self::Unknown(source.to_string()),
        }
    }

    pub fn to_source_string(&self) -> &str {
        match self {
            Self::RubyGems => "rubygems",
            Self::Npm => "npm",
            Self::Yarn => "yarn",
            Self::Python => "python",
            Self::Pip => "pip",
            Self::Pipenv => "pipenv",
            Self::Poetry => "poetry",
            Self::Maven => "maven",
            Self::Gradle => "gradle",
            Self::NuGet => "nuget",
            Self::Composer => "composer",
            Self::Go => "go",
            Self::Cargo => "cargo",
            Self::CocoaPods => "cocoapods",
            Self::Carthage => "carthage",
            Self::SwiftPM => "swift",
            Self::Conda => "conda",
            Self::Terraform => "terraform",
            Self::Docker => "docker",
            Self::Alpine => "apk",
            Self::Debian => "dpkg",
            Self::Unknown(s) => s,
        }
    }

    pub fn display_name(&self) -> &str {
        match self {
            Self::RubyGems => "RubyGems",
            Self::Npm => "NPM",
            Self::Yarn => "Yarn",
            Self::Python => "PyPI",
            Self::Pip => "Pip",
            Self::Pipenv => "Pipenv",
            Self::Poetry => "Poetry",
            Self::Maven => "Maven",
            Self::Gradle => "Gradle",
            Self::NuGet => "NuGet",
            Self::Composer => "Packagist",
            Self::Go => "Go Modules",
            Self::Cargo => "Cargo",
            Self::CocoaPods => "CocoaPods",
            Self::Carthage => "Carthage",
            Self::SwiftPM => "Swift Package Manager",
            Self::Conda => "Conda",
            Self::Terraform => "Terraform Registry",
            Self::Docker => "Docker Hub",
            Self::Alpine => "Alpine Linux",
            Self::Debian => "Debian",
            Self::Unknown(s) => s,
        }
    }

    pub fn is_javascript(&self) -> bool {
        matches!(self, Self::Npm | Self::Yarn)
    }

    pub fn is_python(&self) -> bool {
        matches!(self, Self::Python | Self::Pip | Self::Pipenv | Self::Poetry | Self::Conda)
    }

    pub fn is_dotnet(&self) -> bool {
        matches!(self, Self::NuGet)
    }

    pub fn is_java(&self) -> bool {
        matches!(self, Self::Maven | Self::Gradle)
    }

    pub fn is_ruby(&self) -> bool {
        matches!(self, Self::RubyGems)
    }

    pub fn is_php(&self) -> bool {
        matches!(self, Self::Composer)
    }

    pub fn is_os_package(&self) -> bool {
        matches!(self, Self::Alpine | Self::Debian)
    }
}

impl fmt::Display for PackageManager {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.display_name())
    }
}

impl From<&str> for PackageManager {
    fn from(source: &str) -> Self {
        Self::from_source(source)
    }
}

impl From<String> for PackageManager {
    fn from(source: String) -> Self {
        Self::from_source(&source)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_from_source() {
        assert_eq!(PackageManager::from_source("rubygems"), PackageManager::RubyGems);
        assert_eq!(PackageManager::from_source("npm"), PackageManager::Npm);
        assert_eq!(PackageManager::from_source("yarn"), PackageManager::Yarn);
        assert_eq!(PackageManager::from_source("python"), PackageManager::Python);
        assert_eq!(PackageManager::from_source("maven"), PackageManager::Maven);
        assert_eq!(PackageManager::from_source("nuget"), PackageManager::NuGet);
        assert_eq!(PackageManager::from_source("composer"), PackageManager::Composer);
        assert_eq!(PackageManager::from_source("unknown"), PackageManager::Unknown("unknown".to_string()));
    }

    #[test]
    fn test_to_source_string() {
        assert_eq!(PackageManager::RubyGems.to_source_string(), "rubygems");
        assert_eq!(PackageManager::Npm.to_source_string(), "npm");
        assert_eq!(PackageManager::Yarn.to_source_string(), "yarn");
        assert_eq!(PackageManager::Python.to_source_string(), "python");
    }

    #[test]
    fn test_display_name() {
        assert_eq!(PackageManager::RubyGems.display_name(), "RubyGems");
        assert_eq!(PackageManager::Npm.display_name(), "NPM");
        assert_eq!(PackageManager::Python.display_name(), "PyPI");
    }

    #[test]
    fn test_type_checks() {
        assert!(PackageManager::Npm.is_javascript());
        assert!(PackageManager::Yarn.is_javascript());
        assert!(!PackageManager::RubyGems.is_javascript());

        assert!(PackageManager::Python.is_python());
        assert!(PackageManager::Pip.is_python());
        assert!(!PackageManager::Npm.is_python());

        assert!(PackageManager::RubyGems.is_ruby());
        assert!(!PackageManager::Npm.is_ruby());

        assert!(PackageManager::Alpine.is_os_package());
        assert!(PackageManager::Debian.is_os_package());
        assert!(!PackageManager::Npm.is_os_package());
    }

    #[test]
    fn test_from_string() {
        let pm: PackageManager = "rubygems".into();
        assert_eq!(pm, PackageManager::RubyGems);

        let pm: PackageManager = String::from("npm").into();
        assert_eq!(pm, PackageManager::Npm);
    }

    #[test]
    fn test_display() {
        assert_eq!(format!("{}", PackageManager::RubyGems), "RubyGems");
        assert_eq!(format!("{}", PackageManager::Python), "PyPI");
    }
}