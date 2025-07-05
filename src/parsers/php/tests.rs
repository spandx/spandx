#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::ComposerParser;
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_composer_parser_can_parse() {
        let parser = ComposerParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/composer.lock").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/package.json").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/path/to/composer.json").as_path()));
    }

    #[tokio::test]
    async fn test_composer_parser_parse_basic() {
        let content = r#"{
            "_readme": [
                "This file locks the dependencies of your project to a known state",
                "Read more about it at https://getcomposer.org/doc/01-basic-usage.md#installing-dependencies"
            ],
            "content-hash": "28b2e9ae8de59b2b5b9e8a6b2c7b4b4b4b4b4b4b",
            "packages": [
                {
                    "name": "symfony/polyfill-ctype",
                    "version": "v1.14.0",
                    "source": {
                        "type": "git",
                        "url": "https://github.com/symfony/polyfill-ctype.git",
                        "reference": "fbdeaec0df06cf3d51c93de80c7eb76e271f5a38"
                    },
                    "dist": {
                        "type": "zip",
                        "url": "https://api.github.com/repos/symfony/polyfill-ctype/zipball/fbdeaec0df06cf3d51c93de80c7eb76e271f5a38",
                        "reference": "fbdeaec0df06cf3d51c93de80c7eb76e271f5a38",
                        "shasum": ""
                    },
                    "require": {
                        "php": ">=5.3.3"
                    },
                    "suggest": {
                        "ext-ctype": "For best performance"
                    },
                    "type": "library",
                    "extra": {
                        "branch-alias": {
                            "dev-master": "1.14-dev"
                        }
                    },
                    "autoload": {
                        "psr-4": {
                            "Symfony\\Polyfill\\Ctype\\": ""
                        },
                        "files": [
                            "bootstrap.php"
                        ]
                    },
                    "notification-url": "https://packagist.org/downloads/",
                    "license": [
                        "MIT"
                    ],
                    "authors": [
                        {
                            "name": "Gert de Pagter",
                            "email": "BackEndTea@gmail.com"
                        },
                        {
                            "name": "Symfony Community",
                            "homepage": "https://symfony.com/contributors"
                        }
                    ],
                    "description": "Symfony polyfill for ctype functions",
                    "homepage": "https://symfony.com",
                    "keywords": [
                        "compatibility",
                        "ctype",
                        "polyfill",
                        "portable"
                    ],
                    "time": "2020-01-13T11:15:53+00:00"
                }
            ],
            "packages-dev": [
                {
                    "name": "mockery/mockery",
                    "version": "1.3.1",
                    "source": {
                        "type": "git",
                        "url": "https://github.com/mockery/mockery.git",
                        "reference": "f69bbde7d7a75d6b2862d9ca8fab1cd28014b4be"
                    },
                    "dist": {
                        "type": "zip",
                        "url": "https://api.github.com/repos/mockery/mockery/zipball/f69bbde7d7a75d6b2862d9ca8fab1cd28014b4be",
                        "reference": "f69bbde7d7a75d6b2862d9ca8fab1cd28014b4be",
                        "shasum": ""
                    },
                    "require": {
                        "hamcrest/hamcrest-php": "^2.0.1",
                        "lib-pcre": ">=7.0",
                        "php": ">=5.6.0"
                    },
                    "require-dev": {
                        "phpunit/phpunit": "^5.7.10|^6.5|^7.0|^8.0"
                    },
                    "type": "library",
                    "extra": {
                        "branch-alias": {
                            "dev-master": "1.3.x-dev"
                        }
                    },
                    "autoload": {
                        "psr-0": {
                            "Mockery": "library/"
                        }
                    },
                    "notification-url": "https://packagist.org/downloads/",
                    "license": [
                        "BSD-3-Clause"
                    ],
                    "authors": [
                        {
                            "name": "Pádraic Brady",
                            "email": "padraic.brady@gmail.com",
                            "homepage": "http://blog.astrumfutura.com"
                        },
                        {
                            "name": "Dave Marshall",
                            "email": "dave.marshall@atstsolutions.co.uk",
                            "homepage": "http://davedevelopment.co.uk"
                        }
                    ],
                    "description": "Mockery is a simple yet flexible PHP mock object framework for use in unit testing with PHPUnit, PHPSpec or any other testing framework. Its core goal is to offer a test double framework with a succint API capable of clearly defining all possible object operations and interactions using a human readable Domain Specific Language (DSL).",
                    "homepage": "https://github.com/mockery/mockery",
                    "keywords": [
                        "BDD",
                        "TDD",
                        "library",
                        "mock",
                        "mock objects",
                        "mockery",
                        "stub",
                        "test",
                        "test double",
                        "testing"
                    ],
                    "time": "2019-12-26T09:49:15+00:00"
                }
            ],
            "aliases": [],
            "minimum-stability": "stable",
            "stability-flags": [],
            "prefer-stable": false,
            "prefer-lowest": false,
            "platform": {
                "php": "^7.2"
            },
            "platform-dev": []
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("composer.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = ComposerParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check production package
        let symfony = result.iter()
            .find(|dep| dep.name == "symfony/polyfill-ctype")
            .expect("Symfony package not found");
        assert_eq!(symfony.version, "v1.14.0");
        assert_eq!(symfony.metadata.get("group"), Some(&"production".to_string()));
        assert_eq!(symfony.metadata.get("type"), Some(&"library".to_string()));
        assert_eq!(symfony.metadata.get("license"), Some(&"MIT".to_string()));
        assert_eq!(symfony.metadata.get("homepage"), Some(&"https://symfony.com".to_string()));
        assert_eq!(symfony.metadata.get("keywords"), Some(&"compatibility,ctype,polyfill,portable".to_string()));
        assert_eq!(symfony.metadata.get("authors"), Some(&"Gert de Pagter,Symfony Community".to_string()));
        
        // Check development package
        let mockery = result.iter()
            .find(|dep| dep.name == "mockery/mockery")
            .expect("Mockery package not found");
        assert_eq!(mockery.version, "1.3.1");
        assert_eq!(mockery.metadata.get("group"), Some(&"development".to_string()));
        assert_eq!(mockery.metadata.get("license"), Some(&"BSD-3-Clause".to_string()));
        assert_eq!(mockery.metadata.get("homepage"), Some(&"https://github.com/mockery/mockery".to_string()));
    }

    #[tokio::test]
    async fn test_composer_parser_empty_packages() {
        let content = r#"{
            "_readme": ["This file locks the dependencies"],
            "content-hash": "28b2e9ae8de59b2b5b9e8a6b2c7b4b4b4b4b4b4b",
            "packages": [],
            "packages-dev": [],
            "aliases": [],
            "minimum-stability": "stable",
            "platform": {}
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("composer.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = ComposerParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_composer_parser_missing_name_or_version() {
        let content = r#"{
            "packages": [
                {
                    "name": "valid/package",
                    "version": "1.0.0",
                    "type": "library"
                },
                {
                    "version": "2.0.0",
                    "type": "library"
                },
                {
                    "name": "missing/version",
                    "type": "library"
                }
            ],
            "packages-dev": []
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("composer.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = ComposerParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include the valid package
        assert_eq!(result.len(), 1);
        
        let valid = result.iter()
            .find(|dep| dep.name == "valid/package")
            .expect("Valid package not found");
        assert_eq!(valid.version, "1.0.0");
    }

    #[tokio::test]
    async fn test_composer_parser_only_dev_packages() {
        let content = r#"{
            "packages": [],
            "packages-dev": [
                {
                    "name": "phpunit/phpunit",
                    "version": "9.5.0",
                    "type": "library",
                    "license": ["BSD-3-Clause"],
                    "description": "The PHP Unit Testing framework."
                }
            ]
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("composer.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = ComposerParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let phpunit = result.iter()
            .find(|dep| dep.name == "phpunit/phpunit")
            .expect("PHPUnit package not found");
        assert_eq!(phpunit.version, "9.5.0");
        assert_eq!(phpunit.metadata.get("group"), Some(&"development".to_string()));
        assert_eq!(phpunit.metadata.get("license"), Some(&"BSD-3-Clause".to_string()));
    }

    #[tokio::test]
    async fn test_composer_parser_metadata_extraction() {
        let content = r#"{
            "packages": [
                {
                    "name": "test/package",
                    "version": "1.0.0",
                    "source": {
                        "type": "git",
                        "url": "https://github.com/test/package.git",
                        "reference": "abc123"
                    },
                    "dist": {
                        "type": "zip",
                        "url": "https://api.github.com/repos/test/package/zipball/abc123",
                        "reference": "abc123",
                        "shasum": "def456"
                    },
                    "type": "library",
                    "description": "A test package",
                    "homepage": "https://example.com",
                    "keywords": ["test", "example"],
                    "license": ["MIT", "Apache-2.0"],
                    "authors": [
                        {
                            "name": "John Doe",
                            "email": "john@example.com"
                        },
                        {
                            "name": "Jane Smith"
                        }
                    ],
                    "time": "2021-01-01T12:00:00+00:00"
                }
            ],
            "packages-dev": []
        }"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("composer.lock");
        fs::write(&file_path, content).unwrap();
        
        let parser = ComposerParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let package = &result.iter().next().unwrap();
        assert_eq!(package.metadata.get("source_url"), Some(&"https://github.com/test/package.git".to_string()));
        assert_eq!(package.metadata.get("source_reference"), Some(&"abc123".to_string()));
        assert_eq!(package.metadata.get("source_type"), Some(&"git".to_string()));
        assert_eq!(package.metadata.get("dist_shasum"), Some(&"def456".to_string()));
        assert_eq!(package.metadata.get("license"), Some(&"MIT,Apache-2.0".to_string()));
        assert_eq!(package.metadata.get("keywords"), Some(&"test,example".to_string()));
        assert_eq!(package.metadata.get("authors"), Some(&"John Doe,Jane Smith".to_string()));
        assert_eq!(package.metadata.get("time"), Some(&"2021-01-01T12:00:00+00:00".to_string()));
    }
}