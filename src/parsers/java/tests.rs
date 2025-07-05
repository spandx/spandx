#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::MavenParser;
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_maven_parser_can_parse() {
        let parser = MavenParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/pom.xml").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/build.gradle").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/package.json").as_path()));
    }

    #[tokio::test]
    async fn test_maven_parser_parse_basic() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-core</artifactId>
            <version>5.3.0</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <version>3.6.0</version>
            <scope>test</scope>
            <optional>true</optional>
        </dependency>
    </dependencies>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 3);
        
        // Check junit dependency
        let junit = result.iter()
            .find(|dep| dep.name == "junit:junit")
            .expect("JUnit dependency not found");
        assert_eq!(junit.version, "3.8.1");
        assert_eq!(junit.metadata.get("group_id"), Some(&"junit".to_string()));
        assert_eq!(junit.metadata.get("artifact_id"), Some(&"junit".to_string()));
        
        // Check spring dependency with scope
        let spring = result.iter()
            .find(|dep| dep.name == "org.springframework:spring-core")
            .expect("Spring dependency not found");
        assert_eq!(spring.version, "5.3.0");
        assert_eq!(spring.metadata.get("scope"), Some(&"compile".to_string()));
        
        // Check mockito dependency with scope and optional
        let mockito = result.iter()
            .find(|dep| dep.name == "org.mockito:mockito-core")
            .expect("Mockito dependency not found");
        assert_eq!(mockito.version, "3.6.0");
        assert_eq!(mockito.metadata.get("scope"), Some(&"test".to_string()));
        assert_eq!(mockito.metadata.get("optional"), Some(&"true".to_string()));
    }

    #[tokio::test]
    async fn test_maven_parser_empty_dependencies() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
    
    <dependencies>
    </dependencies>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_maven_parser_no_dependencies_section() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_maven_parser_with_variables() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0</version>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
        </dependency>
        <dependency>
            <groupId>${project.groupId}</groupId>
            <artifactId>module-b</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-core</artifactId>
            <version>${spring.version}</version>
        </dependency>
    </dependencies>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include junit, other dependencies have unresolved variables
        assert_eq!(result.len(), 1);
        
        let junit = result.iter()
            .find(|dep| dep.name == "junit:junit")
            .expect("JUnit dependency not found");
        assert_eq!(junit.version, "3.8.1");
    }

    #[tokio::test]
    async fn test_maven_parser_missing_required_fields() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
        </dependency>
        <dependency>
            <artifactId>incomplete</artifactId>
            <version>1.0.0</version>
        </dependency>
        <dependency>
            <groupId>org.example</groupId>
            <version>2.0.0</version>
        </dependency>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>no-version</artifactId>
        </dependency>
    </dependencies>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include junit (complete dependency)
        assert_eq!(result.len(), 1);
        
        let junit = result.iter()
            .find(|dep| dep.name == "junit:junit")
            .expect("JUnit dependency not found");
        assert_eq!(junit.version, "3.8.1");
    }

    #[tokio::test]
    async fn test_maven_parser_with_additional_metadata() {
        let content = r#"<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    
    <dependencies>
        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-lang3</artifactId>
            <version>3.12.0</version>
            <type>jar</type>
            <scope>compile</scope>
            <optional>false</optional>
            <classifier>sources</classifier>
        </dependency>
    </dependencies>
</project>"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("pom.xml");
        fs::write(&file_path, content).unwrap();
        
        let parser = MavenParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let commons = &result.iter().next().unwrap();
        assert_eq!(commons.name, "org.apache.commons:commons-lang3");
        assert_eq!(commons.version, "3.12.0");
        assert_eq!(commons.metadata.get("type"), Some(&"jar".to_string()));
        assert_eq!(commons.metadata.get("scope"), Some(&"compile".to_string()));
        assert_eq!(commons.metadata.get("optional"), Some(&"false".to_string()));
        assert_eq!(commons.metadata.get("classifier"), Some(&"sources".to_string()));
    }
}