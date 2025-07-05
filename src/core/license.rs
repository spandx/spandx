use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct License {
    pub id: String,
    pub name: String,
    pub deprecated: bool,
    pub osi_approved: Option<bool>,
    pub fsf_libre: Option<bool>,
    pub reference: String,
    pub reference_number: Option<u32>,
    pub details_url: Option<String>,
    pub see_also: Vec<String>,
    pub license_text: Option<String>,
    pub standard_license_header: Option<String>,
    pub standard_license_template: Option<String>,
    pub cross_refs: Vec<CrossRef>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CrossRef {
    #[serde(rename = "match")]
    pub match_type: String,
    pub url: String,
    pub is_valid: bool,
    pub is_live: bool,
    pub timestamp: String,
    pub is_wayback_link: bool,
    pub order: u32,
}

impl License {
    pub fn new(id: String, name: String) -> Self {
        Self {
            id: id.clone(),
            name,
            deprecated: false,
            osi_approved: None,
            fsf_libre: None,
            reference: format!("https://spdx.org/licenses/{}.html", id),
            reference_number: None,
            details_url: None,
            see_also: Vec::new(),
            license_text: None,
            standard_license_header: None,
            standard_license_template: None,
            cross_refs: Vec::new(),
        }
    }

    pub fn is_osi_approved(&self) -> bool {
        self.osi_approved.unwrap_or(false)
    }

    pub fn is_fsf_libre(&self) -> bool {
        self.fsf_libre.unwrap_or(false)
    }

    pub fn is_deprecated(&self) -> bool {
        self.deprecated
    }

    pub fn short_identifier(&self) -> &str {
        &self.id
    }

    pub fn full_name(&self) -> &str {
        &self.name
    }
}

#[derive(Debug, Clone)]
pub struct LicenseCatalogue {
    licenses: HashMap<String, License>,
    version: String,
    release_date: String,
}

impl LicenseCatalogue {
    pub fn new() -> Self {
        Self {
            licenses: HashMap::new(),
            version: String::new(),
            release_date: String::new(),
        }
    }

    pub fn from_json(json_data: &str) -> Result<Self, serde_json::Error> {
        #[derive(Deserialize)]
        struct LicenseList {
            #[serde(rename = "licenseListVersion")]
            license_list_version: String,
            #[serde(rename = "releaseDate")]
            release_date: String,
            licenses: Vec<License>,
        }

        let license_list: LicenseList = serde_json::from_str(json_data)?;
        let mut catalogue = Self::new();
        catalogue.version = license_list.license_list_version;
        catalogue.release_date = license_list.release_date;

        for license in license_list.licenses {
            catalogue.licenses.insert(license.id.clone(), license);
        }

        Ok(catalogue)
    }

    pub fn add_license(&mut self, license: License) {
        self.licenses.insert(license.id.clone(), license);
    }

    pub fn get_license(&self, id: &str) -> Option<&License> {
        self.licenses.get(id)
    }

    pub fn find_by_name(&self, name: &str) -> Option<&License> {
        self.licenses
            .values()
            .find(|license| license.name.eq_ignore_ascii_case(name))
    }

    pub fn find_similar_by_name(&self, name: &str, threshold: f64) -> Vec<&License> {
        use crate::core::Content;
        
        let mut similar = Vec::new();
        let input_content = Content::from(name);

        for license in self.licenses.values() {
            // Check similarity with license ID
            let id_content = Content::from(license.id.as_str());
            let id_similarity = input_content.similarity_score(&id_content);
            
            // Check similarity with license name  
            let name_content = Content::from(license.name.as_str());
            let name_similarity = input_content.similarity_score(&name_content);
            
            // Use the higher of the two scores
            let best_similarity = id_similarity.max(name_similarity);
            
            if best_similarity >= threshold {
                similar.push(license);
            }
        }

        // Sort by similarity score (highest first)
        similar.sort_by(|a, b| {
            let id_content_a = Content::from(a.id.as_str());
            let name_content_a = Content::from(a.name.as_str());
            let score_a = input_content.similarity_score(&id_content_a)
                .max(input_content.similarity_score(&name_content_a));
                
            let id_content_b = Content::from(b.id.as_str());
            let name_content_b = Content::from(b.name.as_str());
            let score_b = input_content.similarity_score(&id_content_b)
                .max(input_content.similarity_score(&name_content_b));
                
            score_b.partial_cmp(&score_a).unwrap_or(std::cmp::Ordering::Equal)
        });

        similar
    }

    pub fn licenses(&self) -> impl Iterator<Item = &License> {
        self.licenses.values()
    }

    pub fn len(&self) -> usize {
        self.licenses.len()
    }

    pub fn is_empty(&self) -> bool {
        self.licenses.is_empty()
    }

    pub fn version(&self) -> &str {
        &self.version
    }

    pub fn release_date(&self) -> &str {
        &self.release_date
    }
}

impl Default for LicenseCatalogue {
    fn default() -> Self {
        Self::new()
    }
}

// Dice coefficient similarity calculation using new Content-based approach
#[allow(dead_code)]
fn similarity_score(s1: &str, s2: &str) -> f64 {
    use crate::core::Content;
    
    let content1 = Content::from(s1);
    let content2 = Content::from(s2);
    
    // Convert to 0-1 scale to match old behavior
    content1.similarity_score(&content2) / 100.0
}

// Legacy bigram-based similarity (kept for comparison/fallback)
#[allow(dead_code)]
fn bigram_similarity_score(s1: &str, s2: &str) -> f64 {
    if s1 == s2 {
        return 1.0;
    }
    if s1.is_empty() || s2.is_empty() {
        return 0.0;
    }

    let bigrams1 = get_bigrams(s1);
    let bigrams2 = get_bigrams(s2);

    if bigrams1.is_empty() && bigrams2.is_empty() {
        return 1.0;
    }
    if bigrams1.is_empty() || bigrams2.is_empty() {
        return 0.0;
    }

    let intersection_size = bigrams1.iter()
        .filter(|bigram| bigrams2.contains(bigram))
        .count();

    (2.0 * intersection_size as f64) / (bigrams1.len() + bigrams2.len()) as f64
}

#[allow(dead_code)]
fn get_bigrams(s: &str) -> Vec<String> {
    let chars: Vec<char> = s.chars().collect();
    if chars.len() < 2 {
        return vec![s.to_string()];
    }

    chars.windows(2)
        .map(|window| window.iter().collect())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_license_creation() {
        let license = License::new("MIT".to_string(), "MIT License".to_string());
        assert_eq!(license.id, "MIT");
        assert_eq!(license.name, "MIT License");
        assert!(!license.deprecated);
    }

    #[test]
    fn test_license_catalogue() {
        let mut catalogue = LicenseCatalogue::new();
        let license = License::new("MIT".to_string(), "MIT License".to_string());
        
        catalogue.add_license(license);
        assert_eq!(catalogue.len(), 1);
        
        let retrieved = catalogue.get_license("MIT");
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().name, "MIT License");
    }

    #[test]
    fn test_similarity_score() {
        assert_eq!(similarity_score("hello", "hello"), 1.0);
        assert_eq!(similarity_score("", ""), 1.0);
        assert_eq!(similarity_score("hello", ""), 0.0);
        assert!(similarity_score("hello", "hallo") > 0.0);
        assert!(similarity_score("hello", "hallo") < 1.0);
    }

    #[test]
    fn test_find_similar_licenses() {
        let mut catalogue = LicenseCatalogue::new();
        catalogue.add_license(License::new("MIT".to_string(), "MIT License".to_string()));
        catalogue.add_license(License::new("Apache-2.0".to_string(), "Apache License 2.0".to_string()));
        
        let similar = catalogue.find_similar_by_name("MIT", 50.0); // 50% threshold (Content uses 0-100 scale)
        assert_eq!(similar.len(), 1);
        assert_eq!(similar[0].id, "MIT");
    }

    #[test]
    fn test_content_based_similarity() {
        let mut catalogue = LicenseCatalogue::new();
        catalogue.add_license(License::new("MIT".to_string(), "MIT License".to_string()));
        catalogue.add_license(License::new("Apache-2.0".to_string(), "Apache License 2.0".to_string()));
        catalogue.add_license(License::new("BSD-3-Clause".to_string(), "BSD 3-Clause License".to_string()));
        
        // Test partial name match
        let similar = catalogue.find_similar_by_name("MIT License", 80.0);
        assert!(!similar.is_empty());
        assert_eq!(similar[0].id, "MIT");
        
        // Test case insensitive matching
        let similar = catalogue.find_similar_by_name("mit license", 80.0);
        assert!(!similar.is_empty());
        assert_eq!(similar[0].id, "MIT");
        
        // Test ID matching
        let similar = catalogue.find_similar_by_name("mit", 80.0);
        assert!(!similar.is_empty());
        assert_eq!(similar[0].id, "MIT");
    }
}