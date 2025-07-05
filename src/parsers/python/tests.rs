#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::PipfileLockParser;
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_pipfile_lock_parser_can_parse() {
        let parser = PipfileLockParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/Pipfile.lock").as_path()));
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/Pipfile-dev.lock").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/requirements.txt").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/setup.py").as_path()));
    }

    #[tokio::test]
    async fn test_pipfile_lock_parser_parse_basic() {
        let content = r#"{
            "_meta": {
                "hash": {
                    "sha256": "d9b5cc506fc4feb9bf1ae7cadfd3737d5a0bd2b2d6c3fbcf0de3458bab34ad89"
                },
                "pipfile-spec": 6,
                "requires": {
                    "python_version": "3.8"
                },
                "sources": [
                    {
                        "name": "pypi",
                        "url": "https://pypi.org/simple",
                        "verify_ssl": true
                    }
                ]
            },
            "default": {
                "requests": {
                    "hashes": [
                        "sha256:1f1b7d42e254082a9db6279deae68afb421ceba6158efa6131de7b3003ee93fd",
                        "sha256:30f610279e8b2578cab6db20741130331735c781b56053c59c4076da27f06b66"
                    ],
                    "index": "pypi",
                    "version": "==2.25.1"
                },
                "urllib3": {
                    "hashes": [
                        "sha256:2f4da4594db7e1e110a944bb1b551fdf4e6c136ad42e4234131391e21eb5b0df"
                    ],
                    "markers": "python_version >= '2.7'",
                    "version": "==1.26.7"
                }
            },
            "develop": {
                "pytest": {
                    "hashes": [
                        "sha256:50bcad0a0b9c5a72c8e4e7c9855a3ad496ca6a881a3641b4260605450772c54b"
                    ],
                    "index": "pypi",
                    "version": "==6.2.4",
                    "extras": ["dev"]
                }
            }
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("Pipfile.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = PipfileLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 3);
        
        // Check requests dependency
        let requests = result.iter()
            .find(|dep| dep.name == "requests")
            .expect("Requests dependency not found");
        assert_eq!(requests.version, "2.25.1");
        assert_eq!(requests.metadata.get("group"), Some(&"default".to_string()));
        assert_eq!(requests.metadata.get("index"), Some(&"pypi".to_string()));
        assert!(requests.metadata.get("hashes").is_some());
        
        // Check urllib3 dependency with markers
        let urllib3 = result.iter()
            .find(|dep| dep.name == "urllib3")
            .expect("urllib3 dependency not found");
        assert_eq!(urllib3.version, "1.26.7");
        assert_eq!(urllib3.metadata.get("markers"), Some(&"python_version >= '2.7'".to_string()));
        
        // Check pytest dependency in develop group
        let pytest = result.iter()
            .find(|dep| dep.name == "pytest")
            .expect("pytest dependency not found");
        assert_eq!(pytest.version, "6.2.4");
        assert_eq!(pytest.metadata.get("group"), Some(&"develop".to_string()));
        assert_eq!(pytest.metadata.get("extras"), Some(&"dev".to_string()));
    }

    #[tokio::test]
    async fn test_pipfile_lock_parser_empty_groups() {
        let content = r#"{
            "_meta": {
                "hash": {
                    "sha256": "d9b5cc506fc4feb9bf1ae7cadfd3737d5a0bd2b2d6c3fbcf0de3458bab34ad89"
                },
                "pipfile-spec": 6
            },
            "default": {},
            "develop": {}
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("Pipfile.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = PipfileLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_pipfile_lock_parser_missing_version() {
        let content = r#"{
            "_meta": {
                "hash": {
                    "sha256": "d9b5cc506fc4feb9bf1ae7cadfd3737d5a0bd2b2d6c3fbcf0de3458bab34ad89"
                }
            },
            "default": {
                "requests": {
                    "hashes": [
                        "sha256:1f1b7d42e254082a9db6279deae68afb421ceba6158efa6131de7b3003ee93fd"
                    ],
                    "index": "pypi"
                },
                "urllib3": {
                    "version": "==1.26.7",
                    "index": "pypi"
                }
            },
            "develop": {}
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("Pipfile.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = PipfileLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include urllib3, not requests (missing version)
        assert_eq!(result.len(), 1);
        
        let urllib3 = result.iter()
            .find(|dep| dep.name == "urllib3")
            .expect("urllib3 dependency not found");
        assert_eq!(urllib3.version, "1.26.7");
    }

    #[tokio::test]
    async fn test_pipfile_lock_parser_version_canonicalization() {
        let content = r#"{
            "_meta": {
                "hash": {
                    "sha256": "d9b5cc506fc4feb9bf1ae7cadfd3737d5a0bd2b2d6c3fbcf0de3458bab34ad89"
                }
            },
            "default": {
                "package1": {
                    "version": "==1.2.3"
                },
                "package2": {
                    "version": "1.2.3"
                },
                "package3": {
                    "version": ">=1.2.3"
                }
            },
            "develop": {}
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("Pipfile.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = PipfileLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 3);
        
        let package1 = result.iter()
            .find(|dep| dep.name == "package1")
            .expect("package1 not found");
        assert_eq!(package1.version, "1.2.3"); // == stripped
        
        let package2 = result.iter()
            .find(|dep| dep.name == "package2")
            .expect("package2 not found");
        assert_eq!(package2.version, "1.2.3"); // no change
        
        let package3 = result.iter()
            .find(|dep| dep.name == "package3")
            .expect("package3 not found");
        assert_eq!(package3.version, ">=1.2.3"); // no change
    }

    #[tokio::test]
    async fn test_pipfile_lock_parser_only_develop_group() {
        let content = r#"{
            "_meta": {
                "hash": {
                    "sha256": "d9b5cc506fc4feb9bf1ae7cadfd3737d5a0bd2b2d6c3fbcf0de3458bab34ad89"
                }
            },
            "develop": {
                "pytest": {
                    "hashes": [
                        "sha256:50bcad0a0b9c5a72c8e4e7c9855a3ad496ca6a881a3641b4260605450772c54b"
                    ],
                    "index": "pypi",
                    "version": "==6.2.4"
                }
            }
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("Pipfile.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = PipfileLockParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let pytest = result.iter()
            .find(|dep| dep.name == "pytest")
            .expect("pytest dependency not found");
        assert_eq!(pytest.version, "6.2.4");
        assert_eq!(pytest.metadata.get("group"), Some(&"develop".to_string()));
    }
}