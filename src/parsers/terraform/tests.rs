#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::TerraformLockParser;
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_terraform_lock_parser_can_parse() {
        let parser = TerraformLockParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/.terraform.lock.hcl").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/main.tf").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/terraform.tfstate").as_path()));
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_parse_basic() {
        let content = r#"# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "3.39.0"
  constraints = "~> 3.27"
  hashes = [
    "h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE=",
    "zh:2014b397dd93fa55f2f2d1338c19e5b2b77b025a76a6b1fceea0b8696e984b9c",
    "zh:23d59c68ab50148a0f5c911a801734e9934a1fccd41118a8efb5194135cbd360",
  ]
}

provider "registry.terraform.io/hashicorp/random" {
  version = "3.1.0"
  hashes = [
    "h1:rKYu5ZUbXwrLG1w81k7H3nce/Ys6yAxXhWcbtk36HjY=",
    "zh:2bbb3339f0643b5daa07480ef4397bd23a79963cc364cdfbb4e86354cb7725bc",
  ]
}
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check AWS provider
        let aws = result.iter()
            .find(|dep| dep.name == "registry.terraform.io/hashicorp/aws")
            .expect("AWS provider not found");
        assert_eq!(aws.version, "3.39.0");
        assert_eq!(aws.metadata.get("constraints"), Some(&"~> 3.27".to_string()));
        assert_eq!(aws.metadata.get("registry"), Some(&"registry.terraform.io".to_string()));
        assert_eq!(aws.metadata.get("namespace"), Some(&"hashicorp".to_string()));
        assert_eq!(aws.metadata.get("name"), Some(&"aws".to_string()));
        assert!(aws.metadata.get("hashes").is_some());
        
        // Check Random provider
        let random = result.iter()
            .find(|dep| dep.name == "registry.terraform.io/hashicorp/random")
            .expect("Random provider not found");
        assert_eq!(random.version, "3.1.0");
        assert_eq!(random.metadata.get("registry"), Some(&"registry.terraform.io".to_string()));
        assert_eq!(random.metadata.get("namespace"), Some(&"hashicorp".to_string()));
        assert_eq!(random.metadata.get("name"), Some(&"random".to_string()));
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_empty_file() {
        let content = r#"# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_single_provider() {
        let content = r#"provider "registry.terraform.io/hashicorp/aws" {
  version = "4.0.0"
  constraints = ">= 3.0"
  hashes = [
    "h1:example1234567890abcdef",
  ]
}
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let aws = &result.iter().next().unwrap();
        assert_eq!(aws.name, "registry.terraform.io/hashicorp/aws");
        assert_eq!(aws.version, "4.0.0");
        assert_eq!(aws.metadata.get("constraints"), Some(&">= 3.0".to_string()));
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_missing_version() {
        let content = r#"provider "registry.terraform.io/hashicorp/aws" {
  constraints = "~> 3.27"
  hashes = [
    "h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE=",
  ]
}

provider "registry.terraform.io/hashicorp/random" {
  version = "3.1.0"
  hashes = [
    "h1:rKYu5ZUbXwrLG1w81k7H3nce/Ys6yAxXhWcbtk36HjY=",
  ]
}
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include random provider (AWS missing version)
        assert_eq!(result.len(), 1);
        
        let random = result.iter()
            .find(|dep| dep.name == "registry.terraform.io/hashicorp/random")
            .expect("Random provider not found");
        assert_eq!(random.version, "3.1.0");
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_complex_nested() {
        let content = r#"# This file is maintained automatically by "terraform init".

provider "registry.terraform.io/hashicorp/aws" {
  version     = "4.15.1"
  constraints = "~> 4.0"
  hashes = [
    "h1:1iA2SdDzmQh6UfM0/AjWW/+e4DWlOXhYFiOJd7GhKdM=",
    "zh:1d148c5c889c636765b9e15a37f9c7e0a4b94821cb58e0b31e3e0ac0e2dfdeeb",
    "zh:2fcdb8ae4a2267e45a5e10b5e0b0ab50f5e2f32c21622b4050c8e60ad7d45bd7",
  ]
}

provider "registry.terraform.io/hashicorp/kubernetes" {
  version     = "2.11.0"
  constraints = ">= 2.0.0"
  hashes = [
    "h1:T65SuPpnCHSfLd3c2bsv0q9ZfjCFEH6jTUBOE1Fs7Bg=",
    "zh:143a19dd0ea3b07fc5e3d9231f3c2d01f92894385c98a67327de74c76c715843",
    "zh:1fc757d209e09c3cf7848e4274daa32408c07743698fbed10ee52a4a479b62b6",
  ]
}
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check AWS provider
        let aws = result.iter()
            .find(|dep| dep.name == "registry.terraform.io/hashicorp/aws")
            .expect("AWS provider not found");
        assert_eq!(aws.version, "4.15.1");
        assert_eq!(aws.metadata.get("constraints"), Some(&"~> 4.0".to_string()));
        
        // Check Kubernetes provider
        let k8s = result.iter()
            .find(|dep| dep.name == "registry.terraform.io/hashicorp/kubernetes")
            .expect("Kubernetes provider not found");
        assert_eq!(k8s.version, "2.11.0");
        assert_eq!(k8s.metadata.get("constraints"), Some(&">= 2.0.0".to_string()));
        assert_eq!(k8s.metadata.get("namespace"), Some(&"hashicorp".to_string()));
        assert_eq!(k8s.metadata.get("name"), Some(&"kubernetes".to_string()));
    }

    #[tokio::test]
    async fn test_terraform_lock_parser_no_constraints() {
        let content = r#"provider "registry.terraform.io/hashicorp/local" {
  version = "2.2.2"
  hashes = [
    "h1:5UYW2wJ320IggrzLt8tLD6AM9s9R5l8zjIgf3aafWAY=",
  ]
}
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join(".terraform.lock.hcl");
        fs::write(&file_path, content).unwrap();
        
        let parser = TerraformLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let local = &result.iter().next().unwrap();
        assert_eq!(local.name, "registry.terraform.io/hashicorp/local");
        assert_eq!(local.version, "2.2.2");
        assert_eq!(local.metadata.get("constraints"), None); // No constraints specified
        assert!(local.metadata.get("hashes").is_some());
    }
}