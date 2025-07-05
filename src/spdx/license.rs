use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct License {
    pub id: String,
    pub name: String,
    pub reference: String,
    pub url: Option<String>,
    pub deprecated_license_id: Option<bool>,
    pub osi_approved: Option<bool>,
    pub see_also: Option<Vec<String>>,
    pub reference_number: Option<u32>,
}

impl License {
    pub fn new(id: String, name: String, reference: String) -> Self {
        Self {
            id,
            name,
            reference,
            url: None,
            deprecated_license_id: None,
            osi_approved: None,
            see_also: None,
            reference_number: None,
        }
    }

    pub fn unknown(text: &str) -> Self {
        Self::new(
            "Nonstandard".to_string(),
            text.to_string(),
            "Nonstandard".to_string(),
        )
    }

    pub fn is_deprecated(&self) -> bool {
        self.deprecated_license_id.unwrap_or(false)
    }

    pub fn is_osi_approved(&self) -> bool {
        self.osi_approved.unwrap_or(false)
    }
}

impl std::cmp::Ord for License {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.id.cmp(&other.id)
    }
}

impl std::cmp::PartialOrd for License {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl std::cmp::Eq for License {}

impl std::fmt::Display for License {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.id)
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum LicenseTree {
    License(String),
    Binary {
        left: Box<LicenseTree>,
        op: String,
        right: Box<LicenseTree>,
    },
    With {
        license: Box<LicenseTree>,
        exception: String,
    },
    Parenthesized(Box<LicenseTree>),
}

#[derive(Debug, Clone)]
pub struct CompositeLicense {
    tree: LicenseTree,
    catalogue: HashMap<String, License>,
}

impl CompositeLicense {
    pub fn from_expression(
        expression: &str,
        catalogue: &HashMap<String, License>,
    ) -> Result<Self, String> {
        use crate::spdx::expression::ExpressionParser;
        
        let parser = ExpressionParser::new();
        let tree = parser.parse(expression)?;
        
        Ok(Self {
            tree,
            catalogue: catalogue.clone(),
        })
    }

    pub fn id(&self) -> String {
        self.tree_to_string(&self.tree)
    }

    pub fn name(&self) -> String {
        self.tree_to_name(&self.tree)
    }

    fn tree_to_string(&self, tree: &LicenseTree) -> String {
        match tree {
            LicenseTree::License(id) => id.clone(),
            LicenseTree::Binary { left, op, right } => {
                format!(
                    "{} {} {}",
                    self.tree_to_string(left),
                    op,
                    self.tree_to_string(right)
                )
            }
            LicenseTree::With { license, exception } => {
                format!("{} WITH {}", self.tree_to_string(license), exception)
            }
            LicenseTree::Parenthesized(inner) => {
                format!("({})", self.tree_to_string(inner))
            }
        }
    }

    fn tree_to_name(&self, tree: &LicenseTree) -> String {
        match tree {
            LicenseTree::License(id) => {
                if let Some(license) = self.catalogue.get(id) {
                    license.name.clone()
                } else {
                    id.clone()
                }
            }
            LicenseTree::Binary { left, op, right } => {
                format!(
                    "{} {} {}",
                    self.tree_to_name(left),
                    op,
                    self.tree_to_name(right)
                )
            }
            LicenseTree::With { license, exception } => {
                format!("{} WITH {}", self.tree_to_name(license), exception)
            }
            LicenseTree::Parenthesized(inner) => {
                format!("({})", self.tree_to_name(inner))
            }
        }
    }
}

impl std::fmt::Display for CompositeLicense {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.id())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_license_creation() {
        let license = License::new(
            "MIT".to_string(),
            "MIT License".to_string(),
            "https://opensource.org/licenses/MIT".to_string(),
        );
        assert_eq!(license.id, "MIT");
        assert_eq!(license.name, "MIT License");
        assert!(!license.is_deprecated());
        assert!(!license.is_osi_approved());
    }

    #[test]
    fn test_license_unknown() {
        let license = License::unknown("Custom License");
        assert_eq!(license.id, "Nonstandard");
        assert_eq!(license.name, "Custom License");
        assert_eq!(license.reference, "Nonstandard");
    }

    #[test]
    fn test_license_display() {
        let license = License::new(
            "Apache-2.0".to_string(),
            "Apache License 2.0".to_string(),
            "https://www.apache.org/licenses/LICENSE-2.0".to_string(),
        );
        assert_eq!(format!("{}", license), "Apache-2.0");
    }

    #[test]
    fn test_license_ordering() {
        let mut licenses = vec![
            License::new("MIT".to_string(), "MIT".to_string(), "".to_string()),
            License::new("Apache-2.0".to_string(), "Apache".to_string(), "".to_string()),
            License::new("GPL-3.0".to_string(), "GPL".to_string(), "".to_string()),
        ];
        
        licenses.sort();
        
        assert_eq!(licenses[0].id, "Apache-2.0");
        assert_eq!(licenses[1].id, "GPL-3.0");
        assert_eq!(licenses[2].id, "MIT");
    }
}