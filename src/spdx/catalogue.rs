use crate::spdx::license::License;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tokio::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SpdxLicenseList {
    #[serde(rename = "licenseListVersion")]
    license_list_version: String,
    licenses: Vec<SpdxLicenseData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SpdxLicenseData {
    #[serde(rename = "licenseId")]
    license_id: String,
    name: String,
    reference: String,
    #[serde(rename = "detailsUrl")]
    details_url: Option<String>,
    #[serde(rename = "referenceNumber")]
    reference_number: Option<u32>,
    #[serde(rename = "isDeprecatedLicenseId")]
    is_deprecated_license_id: Option<bool>,
    #[serde(rename = "isOsiApproved")]
    is_osi_approved: Option<bool>,
    #[serde(rename = "seeAlso")]
    see_also: Option<Vec<String>>,
}

#[derive(Debug, Clone)]
pub struct Catalogue {
    licenses: HashMap<String, License>,
    version: String,
}

impl Catalogue {
    pub fn new() -> Self {
        Self {
            licenses: HashMap::new(),
            version: "unknown".to_string(),
        }
    }

    pub fn from_json(json: &str) -> Result<Self> {
        let license_list: SpdxLicenseList = serde_json::from_str(json)?;
        
        let mut licenses = HashMap::new();
        for license_data in license_list.licenses {
            if !license_data.license_id.is_empty() {
                let license = License {
                    id: license_data.license_id.clone(),
                    name: license_data.name,
                    reference: license_data.reference,
                    url: license_data.details_url,
                    deprecated_license_id: license_data.is_deprecated_license_id,
                    osi_approved: license_data.is_osi_approved,
                    see_also: license_data.see_also,
                    reference_number: license_data.reference_number,
                };
                licenses.insert(license_data.license_id, license);
            }
        }
        
        Ok(Self {
            licenses,
            version: license_list.license_list_version,
        })
    }

    pub async fn from_file(path: &str) -> Result<Self> {
        let content = fs::read_to_string(path).await?;
        Self::from_json(&content)
    }

    pub async fn from_url(url: &str) -> Result<Self> {
        let client = reqwest::Client::new();
        let response = client
            .get(url)
            .header("User-Agent", "spandx-rs/1.0.0")
            .send()
            .await?;
        
        if response.status().is_success() {
            let content = response.text().await?;
            Self::from_json(&content)
        } else {
            Err(anyhow::anyhow!("HTTP request failed: {}", response.status()))
        }
    }

    pub async fn latest() -> Result<Self> {
        const SPDX_LICENSE_URL: &str = "https://spdx.org/licenses/licenses.json";
        
        match Self::from_url(SPDX_LICENSE_URL).await {
            Ok(catalogue) => Ok(catalogue),
            Err(e) => {
                eprintln!("Failed to fetch SPDX licenses from URL: {}", e);
                Self::default_embedded()
            }
        }
    }

    pub fn default_embedded() -> Result<Self> {
        let default_json = include_str!("../../resources/spdx-licenses.json");
        Self::from_json(default_json)
    }

    pub fn get(&self, id: &str) -> Option<&License> {
        self.licenses.get(id)
    }

    pub fn version(&self) -> &str {
        &self.version
    }

    pub fn len(&self) -> usize {
        self.licenses.len()
    }

    pub fn is_empty(&self) -> bool {
        self.licenses.is_empty()
    }

    pub fn iter(&self) -> impl Iterator<Item = (&String, &License)> {
        self.licenses.iter()
    }

    pub fn licenses(&self) -> impl Iterator<Item = &License> {
        self.licenses.values()
    }

    pub fn find<F>(&self, predicate: F) -> Option<&License>
    where
        F: Fn(&License) -> bool,
    {
        self.licenses.values().find(|license| predicate(license))
    }

    pub fn contains_key(&self, id: &str) -> bool {
        self.licenses.contains_key(id)
    }
}

impl std::ops::Index<&str> for Catalogue {
    type Output = License;

    fn index(&self, id: &str) -> &Self::Output {
        &self.licenses[id]
    }
}

impl Default for Catalogue {
    fn default() -> Self {
        Self::default_embedded().unwrap_or_else(|_| Self::new())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_empty_catalogue() {
        let catalogue = Catalogue::new();
        assert!(catalogue.is_empty());
        assert_eq!(catalogue.len(), 0);
        assert_eq!(catalogue.version(), "unknown");
    }

    #[test]
    fn test_from_json() {
        let json = r#"{
            "licenseListVersion": "3.21",
            "licenses": [
                {
                    "licenseId": "MIT",
                    "name": "MIT License",
                    "reference": "https://opensource.org/licenses/MIT",
                    "isOsiApproved": true,
                    "isDeprecatedLicenseId": false,
                    "referenceNumber": 1
                },
                {
                    "licenseId": "Apache-2.0",
                    "name": "Apache License 2.0",
                    "reference": "https://www.apache.org/licenses/LICENSE-2.0",
                    "isOsiApproved": true,
                    "isDeprecatedLicenseId": false,
                    "referenceNumber": 2
                }
            ]
        }"#;

        let catalogue = Catalogue::from_json(json).unwrap();
        assert_eq!(catalogue.len(), 2);
        assert_eq!(catalogue.version(), "3.21");
        
        let mit_license = catalogue.get("MIT").unwrap();
        assert_eq!(mit_license.id, "MIT");
        assert_eq!(mit_license.name, "MIT License");
        assert!(mit_license.is_osi_approved());
        assert!(!mit_license.is_deprecated());
        
        let apache_license = catalogue.get("Apache-2.0").unwrap();
        assert_eq!(apache_license.id, "Apache-2.0");
        assert_eq!(apache_license.name, "Apache License 2.0");
    }

    #[test]
    fn test_from_json_filters_empty_ids() {
        let json = r#"{
            "licenseListVersion": "3.21",
            "licenses": [
                {
                    "licenseId": "",
                    "name": "Empty License",
                    "reference": "https://example.com"
                },
                {
                    "licenseId": "MIT",
                    "name": "MIT License",
                    "reference": "https://opensource.org/licenses/MIT"
                }
            ]
        }"#;

        let catalogue = Catalogue::from_json(json).unwrap();
        assert_eq!(catalogue.len(), 1);
        assert!(catalogue.contains_key("MIT"));
        assert!(!catalogue.contains_key(""));
    }

    #[test]
    fn test_find_predicate() {
        let json = r#"{
            "licenseListVersion": "3.21",
            "licenses": [
                {
                    "licenseId": "MIT",
                    "name": "MIT License",
                    "reference": "https://opensource.org/licenses/MIT",
                    "isOsiApproved": true
                },
                {
                    "licenseId": "Proprietary",
                    "name": "Proprietary License",
                    "reference": "https://example.com",
                    "isOsiApproved": false
                }
            ]
        }"#;

        let catalogue = Catalogue::from_json(json).unwrap();
        
        let osi_license = catalogue.find(|license| license.is_osi_approved());
        assert!(osi_license.is_some());
        assert_eq!(osi_license.unwrap().id, "MIT");
        
        let non_osi_license = catalogue.find(|license| !license.is_osi_approved());
        assert!(non_osi_license.is_some());
        assert_eq!(non_osi_license.unwrap().id, "Proprietary");
    }

    #[test]
    fn test_iteration() {
        let json = r#"{
            "licenseListVersion": "3.21",
            "licenses": [
                {
                    "licenseId": "MIT",
                    "name": "MIT License",
                    "reference": "https://opensource.org/licenses/MIT"
                },
                {
                    "licenseId": "Apache-2.0",
                    "name": "Apache License 2.0",
                    "reference": "https://www.apache.org/licenses/LICENSE-2.0"
                }
            ]
        }"#;

        let catalogue = Catalogue::from_json(json).unwrap();
        
        let license_ids: Vec<String> = catalogue.licenses().map(|l| l.id.clone()).collect();
        assert!(license_ids.contains(&"MIT".to_string()));
        assert!(license_ids.contains(&"Apache-2.0".to_string()));
        assert_eq!(license_ids.len(), 2);
    }
}