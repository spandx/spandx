use anyhow::Result;
use tracing::debug;

use crate::core::{Content, Score};
use crate::spdx::{Catalogue, ExpressionParser};

/// License detection engine with multiple matching strategies
#[derive(Debug)]
pub struct Guess {
    catalogue: Catalogue,
    name_similarity_threshold: f64,
    body_similarity_threshold: f64,
}

/// Input types for license detection
#[derive(Debug, Clone)]
pub enum GuessInput {
    String(String),
    Array(Vec<String>),
    Hash(std::collections::HashMap<String, String>),
}

impl From<String> for GuessInput {
    fn from(s: String) -> Self {
        GuessInput::String(s)
    }
}

impl From<&str> for GuessInput {
    fn from(s: &str) -> Self {
        GuessInput::String(s.to_string())
    }
}

impl From<Vec<String>> for GuessInput {
    fn from(v: Vec<String>) -> Self {
        GuessInput::Array(v)
    }
}

impl From<Vec<&str>> for GuessInput {
    fn from(v: Vec<&str>) -> Self {
        GuessInput::Array(v.into_iter().map(|s| s.to_string()).collect())
    }
}

impl From<std::collections::HashMap<String, String>> for GuessInput {
    fn from(h: std::collections::HashMap<String, String>) -> Self {
        GuessInput::Hash(h)
    }
}

impl Guess {
    /// Create a new Guess instance with default thresholds
    pub fn new(catalogue: Catalogue) -> Self {
        Self {
            catalogue,
            name_similarity_threshold: 85.0, // 85% threshold for name matching (from Ruby)
            body_similarity_threshold: 89.0, // 89% threshold for body matching (from Ruby)
        }
    }

    /// Create a new Guess instance with custom thresholds
    pub fn with_thresholds(catalogue: Catalogue, name_threshold: f64, body_threshold: f64) -> Self {
        Self {
            catalogue,
            name_similarity_threshold: name_threshold,
            body_similarity_threshold: body_threshold,
        }
    }

    /// Main license detection method
    pub async fn detect_license(&self, input: GuessInput) -> Result<String> {
        match input {
            GuessInput::String(content) => self.detect_from_string(&content).await,
            GuessInput::Array(licenses) => self.detect_from_array(&licenses).await,
            GuessInput::Hash(metadata) => self.detect_from_hash(&metadata).await,
        }
    }

    /// Detect license from a single string (license name or content)
    async fn detect_from_string(&self, content: &str) -> Result<String> {
        let content = content.trim();
        
        if content.is_empty() {
            return Ok("unknown".to_string());
        }

        debug!("Detecting license from string: {}", &content[..std::cmp::min(100, content.len())]);

        // Strategy 1: Try exact match in catalogue
        if let Some(license) = self.catalogue.get(content) {
            debug!("Found exact match: {}", license.id);
            return Ok(license.id.clone());
        }

        // Strategy 2: Try parsing as SPDX expression
        let parser = ExpressionParser::new();
        if let Ok(expression) = parser.parse(content) {
            debug!("Parsed as SPDX expression: {:?}", expression);
            return Ok(content.to_string()); // Return original expression string
        }

        // Strategy 3: Try name similarity matching
        if let Some(license_id) = self.find_similar_name(content).await? {
            debug!("Found similar name: {}", license_id);
            return Ok(license_id);
        }

        // Strategy 4: Try body/content similarity matching
        if content.len() > 50 { // Only try body matching for longer content
            if let Some(license_id) = self.find_similar_body(content).await? {
                debug!("Found similar body: {}", license_id);
                return Ok(license_id);
            }
        }

        debug!("No match found, returning unknown");
        Ok("unknown".to_string())
    }

    /// Detect license from an array of license strings
    async fn detect_from_array(&self, licenses: &[String]) -> Result<String> {
        if licenses.is_empty() {
            return Ok("unknown".to_string());
        }

        debug!("Detecting license from array of {} items", licenses.len());

        // Try each license string until we find a match
        for license_str in licenses {
            let result = self.detect_from_string(license_str).await?;
            if result != "unknown" {
                return Ok(result);
            }
        }

        // If no individual matches, try combining them as an expression
        let combined = licenses.join(" AND ");
        let parser = ExpressionParser::new();
        if let Ok(_expression) = parser.parse(&combined) {
            debug!("Parsed combined array as SPDX expression: {}", combined);
            return Ok(combined);
        }

        Ok("unknown".to_string())
    }

    /// Detect license from a hash/map of metadata
    async fn detect_from_hash(&self, metadata: &std::collections::HashMap<String, String>) -> Result<String> {
        debug!("Detecting license from hash with {} keys", metadata.len());

        // Look for common license fields
        let license_fields = [
            "license", "License", "LICENSE",
            "license_id", "licenseId", "license-id",
            "spdx_id", "spdxId", "spdx-id",
            "name", "title",
        ];

        for field in &license_fields {
            if let Some(value) = metadata.get(*field) {
                let result = self.detect_from_string(value).await?;
                if result != "unknown" {
                    debug!("Found license in field '{}': {}", field, result);
                    return Ok(result);
                }
            }
        }

        // Try license text/body fields
        let body_fields = [
            "text", "body", "content", "license_text", "licenseText",
            "full_text", "fullText", "description",
        ];

        for field in &body_fields {
            if let Some(value) = metadata.get(*field) {
                if value.len() > 100 { // Only try body matching for substantial content
                    let result = self.detect_from_string(value).await?;
                    if result != "unknown" {
                        debug!("Found license in body field '{}': {}", field, result);
                        return Ok(result);
                    }
                }
            }
        }

        Ok("unknown".to_string())
    }

    /// Find similar license by name using Dice coefficient
    async fn find_similar_name(&self, name: &str) -> Result<Option<String>> {
        let input_content = Content::from(name);
        let mut best_score = Score::zero();

        for license in self.catalogue.licenses() {
            // Try license ID
            let id_content = Content::from(license.id.as_str());
            let id_score = input_content.similarity_score(&id_content);
            
            if id_score >= self.name_similarity_threshold {
                best_score.update_if_better(license.id.clone(), id_score);
            }

            // Try license name
            let name_content = Content::from(license.name.as_str());
            let name_score = input_content.similarity_score(&name_content);
            
            if name_score >= self.name_similarity_threshold {
                best_score.update_if_better(license.id.clone(), name_score);
            }
        }

        if best_score.meets_threshold(self.name_similarity_threshold) {
            debug!("Best name similarity: {}", best_score);
            Ok(Some(best_score.license_id().to_string()))
        } else {
            Ok(None)
        }
    }

    /// Find similar license by body/content using Dice coefficient
    async fn find_similar_body(&self, content: &str) -> Result<Option<String>> {
        let input_content = Content::from(content);
        let mut best_score = Score::zero();

        for license in self.catalogue.licenses() {
            // Skip deprecated licenses for body matching
            if license.is_deprecated() {
                continue;
            }

            // Try to get license text
            if let Some(license_text) = self.get_license_text(&license.id).await? {
                let license_content = Content::from(license_text.as_str());
                let score = input_content.similarity_score(&license_content);
                
                if score >= self.body_similarity_threshold {
                    best_score.update_if_better(license.id.clone(), score);
                }
            }
        }

        if best_score.meets_threshold(self.body_similarity_threshold) {
            debug!("Best body similarity: {}", best_score);
            Ok(Some(best_score.license_id().to_string()))
        } else {
            Ok(None)
        }
    }

    /// Get license text from SPDX repository or other sources
    async fn get_license_text(&self, license_id: &str) -> Result<Option<String>> {
        // Try to load from SPDX license text
        // This would integrate with the Git operations to load from the SPDX repository
        // For now, return None to avoid blocking the implementation
        
        // TODO: Integrate with GitOperations to load license text from spdx repository
        // Something like:
        // let git_ops = GitOperations::new(...);
        // let license_text = git_ops.read_file("spdx", &format!("text/{}.txt", license_id)).await?;
        
        debug!("License text loading not yet implemented for: {}", license_id);
        Ok(None)
    }

    /// Get the name similarity threshold
    pub fn name_similarity_threshold(&self) -> f64 {
        self.name_similarity_threshold
    }

    /// Get the body similarity threshold
    pub fn body_similarity_threshold(&self) -> f64 {
        self.body_similarity_threshold
    }

    /// Update thresholds
    pub fn set_thresholds(&mut self, name_threshold: f64, body_threshold: f64) {
        self.name_similarity_threshold = name_threshold;
        self.body_similarity_threshold = body_threshold;
    }

    /// Find all licenses above a similarity threshold
    pub async fn find_all_similar(&self, input: &str, threshold: f64) -> Result<Vec<Score>> {
        let input_content = Content::from(input);
        let mut scores = Vec::new();

        for license in self.catalogue.licenses() {
            // Check ID similarity
            let id_content = Content::from(license.id.as_str());
            let id_score = input_content.similarity_score(&id_content);
            
            if id_score >= threshold {
                scores.push(Score::new(license.id.clone(), id_score));
            }

            // Check name similarity
            let name_content = Content::from(license.name.as_str());
            let name_score = input_content.similarity_score(&name_content);
            
            if name_score >= threshold {
                scores.push(Score::new(format!("{} (name)", license.id), name_score));
            }
        }

        // Sort by score descending
        scores.sort_by(|a, b| b.score().partial_cmp(&a.score()).unwrap_or(std::cmp::Ordering::Equal));
        
        Ok(scores)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    fn create_test_catalogue() -> Catalogue {
        // Create a minimal catalogue for testing
        Catalogue::default() // This will use the built-in SPDX licenses
    }

    #[tokio::test]
    async fn test_guess_creation() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        assert_eq!(guess.name_similarity_threshold(), 85.0);
        assert_eq!(guess.body_similarity_threshold(), 89.0);
    }

    #[tokio::test]
    async fn test_guess_with_custom_thresholds() {
        let catalogue = create_test_catalogue();
        let guess = Guess::with_thresholds(catalogue, 80.0, 85.0);
        
        assert_eq!(guess.name_similarity_threshold(), 80.0);
        assert_eq!(guess.body_similarity_threshold(), 85.0);
    }

    #[tokio::test]
    async fn test_detect_exact_match() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let result = guess.detect_license("MIT".into()).await.unwrap();
        assert_eq!(result, "MIT");
    }

    #[tokio::test]
    async fn test_detect_empty_string() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let result = guess.detect_license("".into()).await.unwrap();
        assert_eq!(result, "unknown");
        
        let result = guess.detect_license("   ".into()).await.unwrap();
        assert_eq!(result, "unknown");
    }

    #[tokio::test]
    async fn test_detect_spdx_expression() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let result = guess.detect_license("MIT AND Apache-2.0".into()).await.unwrap();
        assert_eq!(result, "MIT AND Apache-2.0");
        
        let result = guess.detect_license("(MIT OR Apache-2.0)".into()).await.unwrap();
        assert_eq!(result, "(MIT OR Apache-2.0)");
    }

    #[tokio::test]
    async fn test_detect_from_array() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let licenses = vec!["MIT".to_string(), "Apache-2.0".to_string()];
        let result = guess.detect_license(licenses.into()).await.unwrap();
        assert_eq!(result, "MIT"); // Should return first match
        
        let empty_array: Vec<String> = vec![];
        let result = guess.detect_license(empty_array.into()).await.unwrap();
        assert_eq!(result, "unknown");
    }

    #[tokio::test]
    async fn test_detect_from_hash() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let mut metadata = HashMap::new();
        metadata.insert("license".to_string(), "MIT".to_string());
        metadata.insert("author".to_string(), "Someone".to_string());
        
        let result = guess.detect_license(metadata.into()).await.unwrap();
        assert_eq!(result, "MIT");
    }

    #[tokio::test]
    async fn test_detect_from_hash_no_license() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let mut metadata = HashMap::new();
        metadata.insert("author".to_string(), "Someone".to_string());
        metadata.insert("version".to_string(), "1.0.0".to_string());
        
        let result = guess.detect_license(metadata.into()).await.unwrap();
        assert_eq!(result, "unknown");
    }

    #[tokio::test]
    async fn test_guess_input_conversions() {
        // Test string conversions
        let input1: GuessInput = "MIT".into();
        let input2: GuessInput = "MIT".to_string().into();
        
        match (input1, input2) {
            (GuessInput::String(s1), GuessInput::String(s2)) => {
                assert_eq!(s1, "MIT");
                assert_eq!(s2, "MIT");
            }
            _ => panic!("Expected String variants"),
        }
        
        // Test array conversions
        let input3: GuessInput = vec!["MIT", "Apache-2.0"].into();
        let input4: GuessInput = vec!["MIT".to_string(), "Apache-2.0".to_string()].into();
        
        match (input3, input4) {
            (GuessInput::Array(a1), GuessInput::Array(a2)) => {
                assert_eq!(a1, vec!["MIT", "Apache-2.0"]);
                assert_eq!(a2, vec!["MIT", "Apache-2.0"]);
            }
            _ => panic!("Expected Array variants"),
        }
    }

    #[tokio::test]
    async fn test_find_all_similar() {
        let catalogue = create_test_catalogue();
        let guess = Guess::new(catalogue);
        
        let scores = guess.find_all_similar("MIT License", 50.0).await.unwrap();
        
        // Should find some matches with MIT in the name
        assert!(!scores.is_empty());
        
        // Check that scores are sorted in descending order
        for i in 1..scores.len() {
            assert!(scores[i-1].score() >= scores[i].score());
        }
    }

    #[tokio::test]
    async fn test_threshold_updates() {
        let catalogue = create_test_catalogue();
        let mut guess = Guess::new(catalogue);
        
        guess.set_thresholds(75.0, 80.0);
        assert_eq!(guess.name_similarity_threshold(), 75.0);
        assert_eq!(guess.body_similarity_threshold(), 80.0);
    }
}