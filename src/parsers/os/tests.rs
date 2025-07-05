#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::parser::Parser;
    use crate::parsers::{ApkParser, DpkgParser};
    use camino::Utf8PathBuf;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_apk_parser_can_parse() {
        let parser = ApkParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/lib/apk/db/installed").as_path()));
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/installed").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/var/lib/dpkg/status").as_path()));
    }

    #[test]
    fn test_dpkg_parser_can_parse() {
        let parser = DpkgParser::new();
        
        assert!(parser.can_parse(Utf8PathBuf::from("/var/lib/dpkg/status").as_path()));
        assert!(parser.can_parse(Utf8PathBuf::from("/path/to/status").as_path()));
        assert!(!parser.can_parse(Utf8PathBuf::from("/lib/apk/db/installed").as_path()));
    }

    #[tokio::test]
    async fn test_apk_parser_parse_basic() {
        let content = r#"C:Q1SJUcZmtG6o3F1bu1Pfo7HuBsGwY=
P:musl
V:1.1.24-r9
A:x86_64
S:377256
I:614400
T:the musl c library (libc) implementation
U:https://musl.libc.org/
L:MIT
o:musl
m:Timo Teräs <timo.teras@iki.fi>
t:1592662716

C:Q1abc123def456
P:busybox
V:1.32.0-r8
A:x86_64
S:924672
I:1851392
T:Swiss Army Knife of Embedded Linux
U:https://busybox.net/
L:GPL-2.0-only
o:busybox
m:Sören Tempel <soeren+alpine@soeren-tempel.net>
t:1592662800
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("installed");
        fs::write(&file_path, content).unwrap();
        
        let parser = ApkParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check musl package
        let musl = result.iter()
            .find(|dep| dep.name == "musl")
            .expect("musl package not found");
        assert_eq!(musl.version, "1.1.24-r9");
        assert_eq!(musl.metadata.get("architecture"), Some(&"x86_64".to_string()));
        assert_eq!(musl.metadata.get("license"), Some(&"MIT".to_string()));
        assert_eq!(musl.metadata.get("description"), Some(&"the musl c library (libc) implementation".to_string()));
        assert_eq!(musl.metadata.get("url"), Some(&"https://musl.libc.org/".to_string()));
        
        // Check busybox package
        let busybox = result.iter()
            .find(|dep| dep.name == "busybox")
            .expect("busybox package not found");
        assert_eq!(busybox.version, "1.32.0-r8");
        assert_eq!(busybox.metadata.get("license"), Some(&"GPL-2.0-only".to_string()));
    }

    #[tokio::test]
    async fn test_dpkg_parser_parse_basic() {
        let content = r#"Package: adduser
Status: install ok installed
Priority: important
Section: admin
Installed-Size: 849
Maintainer: Debian Adduser Developers <adduser@packages.debian.org>
Architecture: all
Multi-Arch: foreign
Version: 3.118
Depends: passwd, debconf (>= 0.5) | debconf-2.0
Suggests: liblocale-gettext-perl, perl
Description: add and remove users and groups
 This package includes the 'adduser' and 'deluser' commands for creating
 and removing users.
 .
 With the standard Debian policy, UIDs from 1000 upwards are intended for
 regular users, and UIDs from 100-999 for services.

Package: base-files
Status: install ok installed
Priority: required
Section: admin
Installed-Size: 384
Maintainer: Santiago Vila <sanvila@debian.org>
Architecture: amd64
Multi-Arch: foreign
Version: 11.1+deb11u5
Replaces: base
Provides: base
Conflicts: base
Description: Debian base system miscellaneous files
 This package contains the basic filesystem hierarchy of a Debian system, and
 several important miscellaneous files, such as /etc/debian_version,
 /etc/host.conf, /etc/issue, /etc/motd, /etc/profile, and others,
 and the text of several common licenses in use on Debian systems.
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("status");
        fs::write(&file_path, content).unwrap();
        
        let parser = DpkgParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 2);
        
        // Check adduser package
        let adduser = result.iter()
            .find(|dep| dep.name == "adduser")
            .expect("adduser package not found");
        assert_eq!(adduser.version, "3.118");
        assert_eq!(adduser.metadata.get("priority"), Some(&"important".to_string()));
        assert_eq!(adduser.metadata.get("section"), Some(&"admin".to_string()));
        assert_eq!(adduser.metadata.get("architecture"), Some(&"all".to_string()));
        assert_eq!(adduser.metadata.get("depends"), Some(&"passwd, debconf (>= 0.5) | debconf-2.0".to_string()));
        assert!(adduser.metadata.get("description").unwrap().contains("add and remove users and groups"));
        
        // Check base-files package
        let base_files = result.iter()
            .find(|dep| dep.name == "base-files")
            .expect("base-files package not found");
        assert_eq!(base_files.version, "11.1+deb11u5");
        assert_eq!(base_files.metadata.get("architecture"), Some(&"amd64".to_string()));
        assert_eq!(base_files.metadata.get("provides"), Some(&"base".to_string()));
    }

    #[tokio::test]
    async fn test_apk_parser_empty_file() {
        let content = "";

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("installed");
        fs::write(&file_path, content).unwrap();
        
        let parser = ApkParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_dpkg_parser_empty_file() {
        let content = "";

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("status");
        fs::write(&file_path, content).unwrap();
        
        let parser = DpkgParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 0);
    }

    #[tokio::test]
    async fn test_apk_parser_missing_required_fields() {
        let content = r#"C:Q1SJUcZmtG6o3F1bu1Pfo7HuBsGwY=
P:musl
V:1.1.24-r9
A:x86_64

C:Q2abc123def456
P:invalid-package
A:x86_64

P:another-invalid
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("installed");
        fs::write(&file_path, content).unwrap();
        
        let parser = ApkParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include musl (complete package)
        assert_eq!(result.len(), 1);
        
        let musl = result.iter()
            .find(|dep| dep.name == "musl")
            .expect("musl package not found");
        assert_eq!(musl.version, "1.1.24-r9");
    }

    #[tokio::test]
    async fn test_dpkg_parser_not_installed_packages() {
        let content = r#"Package: installed-package
Status: install ok installed
Version: 1.0.0
Architecture: amd64

Package: config-only-package
Status: deinstall ok config-files
Version: 2.0.0
Architecture: amd64

Package: half-configured-package
Status: install ok half-configured
Version: 3.0.0
Architecture: amd64
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("status");
        fs::write(&file_path, content).unwrap();
        
        let parser = DpkgParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        // Should only include the fully installed package
        assert_eq!(result.len(), 1);
        
        let installed = result.iter()
            .find(|dep| dep.name == "installed-package")
            .expect("installed package not found");
        assert_eq!(installed.version, "1.0.0");
    }

    #[tokio::test]
    async fn test_dpkg_parser_multiline_description() {
        let content = r#"Package: test-package
Status: install ok installed
Version: 1.0.0
Architecture: amd64
Description: A test package with multiline description
 This is the first line of the extended description.
 .
 This is after a paragraph break.
 This line continues the paragraph.
"#;

        let temp_dir = tempdir().unwrap();
        let file_path = temp_dir.path().join("status");
        fs::write(&file_path, content).unwrap();
        
        let parser = DpkgParser::new();
        let path = Utf8PathBuf::from_path_buf(file_path).unwrap();
        let result = parser.parse(&path).await.unwrap();
        
        assert_eq!(result.len(), 1);
        
        let package = &result.iter().next().unwrap();
        assert_eq!(package.name, "test-package");
        let description = package.metadata.get("description").unwrap();
        assert!(description.contains("A test package with multiline description"));
        assert!(description.contains("This is the first line"));
        assert!(description.contains("paragraph break"));
    }
}