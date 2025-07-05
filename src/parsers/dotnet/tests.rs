#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::{CsprojParser, PackagesConfigParser};
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_csproj_parser_can_parse() {
        let parser = CsprojParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/project.csproj").as_path()));
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/Directory.Build.props").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/packages.config").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/project.sln").as_path()));
    }

    #[test]
    fn test_packages_config_parser_can_parse() {
        let parser = PackagesConfigParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/packages.config").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/project.csproj").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/project.sln").as_path()));
    }

    #[tokio::test]
    async fn test_csproj_parser_parse_basic() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.1" />
    <PackageReference Include="Microsoft.Extensions.Logging" Version="6.0.0" />
    <PackageReference Include="System.Text.Json" Version="6.0.0" PrivateAssets="all" />
  </ItemGroup>
</Project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("test.csproj");
        fs::write(&file_path, content).unwrap();
        
        let parser = CsprojParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 3);
        
        // Check Newtonsoft.Json package
        let newtonsoft = result.iter()
            .find(|dep| dep.name == "Newtonsoft.Json")
            .expect("Newtonsoft.Json package not found");
        assert_eq!(newtonsoft.version, "13.0.1");
        
        // Check Microsoft.Extensions.Logging package
        let logging = result.iter()
            .find(|dep| dep.name == "Microsoft.Extensions.Logging")
            .expect("Microsoft.Extensions.Logging package not found");
        assert_eq!(logging.version, "6.0.0");
        
        // Check System.Text.Json package with PrivateAssets
        let text_json = result.iter()
            .find(|dep| dep.name == "System.Text.Json")
            .expect("System.Text.Json package not found");
        assert_eq!(text_json.version, "6.0.0");
        assert_eq!(text_json.metadata.get("private_assets"), Some(&"all".to_string()));
    }

    #[tokio::test]
    async fn test_csproj_parser_with_child_elements() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="EntityFramework">
      <Version>6.4.4</Version>
      <PrivateAssets>none</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="TestPackage" Update="true">
      <Version>1.0.0</Version>
      <ExcludeAssets>build</ExcludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("test.csproj");
        fs::write(&file_path, content).unwrap();
        
        let parser = CsprojParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check EntityFramework package
        let ef = result.iter()
            .find(|dep| dep.name == "EntityFramework")
            .expect("EntityFramework package not found");
        assert_eq!(ef.version, "6.4.4");
        assert_eq!(ef.metadata.get("private_assets"), Some(&"none".to_string()));
        assert_eq!(ef.metadata.get("include_assets"), Some(&"runtime; build; native; contentfiles; analyzers".to_string()));
        
        // Check TestPackage with Update attribute
        let test_pkg = result.iter()
            .find(|dep| dep.name == "TestPackage")
            .expect("TestPackage not found");
        assert_eq!(test_pkg.version, "1.0.0");
        assert_eq!(test_pkg.metadata.get("exclude_assets"), Some(&"build".to_string()));
    }

    #[tokio::test]
    async fn test_packages_config_parser_parse_basic() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Newtonsoft.Json" version="13.0.1" targetFramework="net472" />
  <package id="NUnit" version="3.13.2" targetFramework="net472" developmentDependency="true" />
  <package id="EntityFramework" version="6.4.4" targetFramework="net472" />
</packages>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("packages.config");
        fs::write(&file_path, content).unwrap();
        
        let parser = PackagesConfigParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 3);
        
        // Check Newtonsoft.Json package
        let newtonsoft = result.iter()
            .find(|dep| dep.name == "Newtonsoft.Json")
            .expect("Newtonsoft.Json package not found");
        assert_eq!(newtonsoft.version, "13.0.1");
        assert_eq!(newtonsoft.metadata.get("target_framework"), Some(&"net472".to_string()));
        
        // Check NUnit package with developmentDependency
        let nunit = result.iter()
            .find(|dep| dep.name == "NUnit")
            .expect("NUnit package not found");
        assert_eq!(nunit.version, "3.13.2");
        assert_eq!(nunit.metadata.get("development_dependency"), Some(&"true".to_string()));
        
        // Check EntityFramework package
        let ef = result.iter()
            .find(|dep| dep.name == "EntityFramework")
            .expect("EntityFramework package not found");
        assert_eq!(ef.version, "6.4.4");
    }

    #[tokio::test]
    async fn test_packages_config_parser_with_child_elements() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="TestPackage">
    <version>1.0.0</version>
    <targetFramework>net48</targetFramework>
    <developmentDependency>false</developmentDependency>
  </package>
</packages>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("packages.config");
        fs::write(&file_path, content).unwrap();
        
        let parser = PackagesConfigParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let package = &result.iter().next().unwrap();
        assert_eq!(package.name, "TestPackage");
        assert_eq!(package.version, "1.0.0");
        assert_eq!(package.metadata.get("target_framework"), Some(&"net48".to_string()));
        assert_eq!(package.metadata.get("development_dependency"), Some(&"false".to_string()));
    }

    #[tokio::test]
    async fn test_csproj_parser_empty_project() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
  </PropertyGroup>
</Project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("test.csproj");
        fs::write(&file_path, content).unwrap();
        
        let parser = CsprojParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_packages_config_parser_empty_packages() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<packages>
</packages>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("packages.config");
        fs::write(&file_path, content).unwrap();
        
        let parser = PackagesConfigParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_csproj_parser_missing_version() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="ValidPackage" Version="1.0.0" />
    <PackageReference Include="NoVersionPackage" />
    <PackageReference Include="EmptyVersionPackage" Version="" />
  </ItemGroup>
</Project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("test.csproj");
        fs::write(&file_path, content).unwrap();
        
        let parser = CsprojParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include ValidPackage
        assert_eq!(result.len(), 1);
        
        let valid = result.iter()
            .find(|dep| dep.name == "ValidPackage")
            .expect("ValidPackage not found");
        assert_eq!(valid.version, "1.0.0");
    }

    #[tokio::test]
    async fn test_packages_config_parser_missing_required_fields() {
        let content = r#"<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="ValidPackage" version="1.0.0" />
  <package version="2.0.0" />
  <package id="NoVersionPackage" />
  <package id="" version="3.0.0" />
</packages>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("packages.config");
        fs::write(&file_path, content).unwrap();
        
        let parser = PackagesConfigParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include ValidPackage
        assert_eq!(result.len(), 1);
        
        let valid = result.iter()
            .find(|dep| dep.name == "ValidPackage")
            .expect("ValidPackage not found");
        assert_eq!(valid.version, "1.0.0");
    }
}