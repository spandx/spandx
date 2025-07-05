use std::collections::HashSet;
use regex::Regex;

/// Represents textual content with similarity scoring capabilities
#[derive(Debug, Clone, PartialEq)]
pub struct Content {
    text: String,
    tokens: HashSet<String>,
}

impl Content {
    /// Create a new Content instance with the given text
    pub fn new(text: String) -> Self {
        let tokens = Self::tokenize(&Self::canonicalize(&text));
        Self { text, tokens }
    }

    /// Get the original text
    pub fn text(&self) -> &str {
        &self.text
    }

    /// Get the tokens
    pub fn tokens(&self) -> &HashSet<String> {
        &self.tokens
    }

    /// Calculate Dice coefficient similarity with another Content instance
    /// Returns a percentage (0.0 - 100.0)
    pub fn similarity_score(&self, other: &Content) -> f64 {
        self.dice_coefficient(other)
    }

    /// Calculate Dice coefficient between two Content instances
    /// Formula: 2 * |X ∩ Y| / (|X| + |Y|) * 100
    pub fn dice_coefficient(&self, other: &Content) -> f64 {
        let overlap = self.tokens.intersection(&other.tokens).count();
        let total = self.tokens.len() + other.tokens.len();
        
        if total == 0 {
            0.0
        } else {
            100.0 * (overlap as f64 * 2.0 / total as f64)
        }
    }

    /// Canonicalize text by converting to lowercase
    fn canonicalize(text: &str) -> String {
        text.to_lowercase()
    }

    /// Tokenize text by extracting alphanumeric words and dots
    /// Matches Ruby regex: /[a-zA-Z\d.]+/
    fn tokenize(text: &str) -> HashSet<String> {
        lazy_static::lazy_static! {
            static ref TOKEN_REGEX: Regex = Regex::new(r"[a-zA-Z\d.]+").unwrap();
        }
        
        TOKEN_REGEX
            .find_iter(text)
            .map(|m| m.as_str().to_string())
            .collect()
    }

    /// Create Content from a string slice
    pub fn from_str(text: &str) -> Self {
        Self::new(text.to_string())
    }

    /// Check if content is empty (no tokens)
    pub fn is_empty(&self) -> bool {
        self.tokens.is_empty()
    }

    /// Get the number of unique tokens
    pub fn token_count(&self) -> usize {
        self.tokens.len()
    }

    /// Get common tokens with another Content instance
    pub fn common_tokens(&self, other: &Content) -> HashSet<String> {
        self.tokens.intersection(&other.tokens).cloned().collect()
    }

    /// Get union of tokens with another Content instance
    pub fn union_tokens(&self, other: &Content) -> HashSet<String> {
        self.tokens.union(&other.tokens).cloned().collect()
    }

    /// Calculate Jaccard similarity coefficient
    /// Formula: |X ∩ Y| / |X ∪ Y| * 100
    pub fn jaccard_coefficient(&self, other: &Content) -> f64 {
        let intersection_size = self.tokens.intersection(&other.tokens).count();
        let union_size = self.tokens.union(&other.tokens).count();
        
        if union_size == 0 {
            0.0
        } else {
            100.0 * (intersection_size as f64 / union_size as f64)
        }
    }

    /// Calculate cosine similarity
    /// Formula: |X ∩ Y| / sqrt(|X| * |Y|) * 100
    pub fn cosine_similarity(&self, other: &Content) -> f64 {
        let intersection_size = self.tokens.intersection(&other.tokens).count();
        let magnitude_product = (self.tokens.len() as f64 * other.tokens.len() as f64).sqrt();
        
        if magnitude_product == 0.0 {
            0.0
        } else {
            100.0 * (intersection_size as f64 / magnitude_product)
        }
    }
}

impl From<String> for Content {
    fn from(text: String) -> Self {
        Self::new(text)
    }
}

impl From<&str> for Content {
    fn from(text: &str) -> Self {
        Self::new(text.to_string())
    }
}

impl std::fmt::Display for Content {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.text)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_content_creation() {
        let content = Content::new("MIT License".to_string());
        assert_eq!(content.text(), "MIT License");
        assert_eq!(content.token_count(), 2);
        assert!(content.tokens().contains("mit"));
        assert!(content.tokens().contains("license"));
    }

    #[test]
    fn test_tokenization() {
        let content = Content::new("MIT License v2.0".to_string());
        let tokens = content.tokens();
        
        assert_eq!(tokens.len(), 3); // v2.0 is a single token (includes dots)
        assert!(tokens.contains("mit"));
        assert!(tokens.contains("license"));
        assert!(tokens.contains("v2.0"));
    }

    #[test]
    fn test_tokenization_with_dots() {
        let content = Content::new("Apache-2.0 License v1.2.3".to_string());
        let tokens = content.tokens();
        
        // Should extract: apache, 2.0, license, v1.2.3
        assert!(tokens.contains("apache"));
        assert!(tokens.contains("2.0"));
        assert!(tokens.contains("license"));
        assert!(tokens.contains("v1.2.3"));
    }

    #[test]
    fn test_canonicalization() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("mit license".to_string());
        
        assert_eq!(content1.tokens(), content2.tokens());
    }

    #[test]
    fn test_dice_coefficient_identical() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT License".to_string());
        
        assert!((content1.dice_coefficient(&content2) - 100.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_dice_coefficient_no_overlap() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("Apache BSD".to_string());
        
        assert!((content1.dice_coefficient(&content2) - 0.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_dice_coefficient_partial_overlap() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD".to_string());
        
        // Tokens: content1 = {mit, license}, content2 = {mit, bsd}
        // Overlap: {mit} = 1
        // Total: 2 + 2 = 4
        // Dice: 2 * 1 / 4 * 100 = 50.0
        assert!((content1.dice_coefficient(&content2) - 50.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_dice_coefficient_empty_content() {
        let content1 = Content::new("".to_string());
        let content2 = Content::new("MIT License".to_string());
        
        assert!((content1.dice_coefficient(&content2) - 0.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_dice_coefficient_both_empty() {
        let content1 = Content::new("".to_string());
        let content2 = Content::new("".to_string());
        
        assert!((content1.dice_coefficient(&content2) - 0.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_similarity_score() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD License".to_string());
        
        // Tokens: content1 = {mit, license}, content2 = {mit, bsd, license}
        // Overlap: {mit, license} = 2
        // Total: 2 + 3 = 5
        // Dice: 2 * 2 / 5 * 100 = 80.0
        assert!((content1.similarity_score(&content2) - 80.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_jaccard_coefficient() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD License".to_string());
        
        // Tokens: content1 = {mit, license}, content2 = {mit, bsd, license}
        // Intersection: {mit, license} = 2
        // Union: {mit, license, bsd} = 3
        // Jaccard: 2 / 3 * 100 = 66.67
        let score = content1.jaccard_coefficient(&content2);
        assert!((score - 66.66666666666667).abs() < 0.01);
    }

    #[test]
    fn test_cosine_similarity() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD License".to_string());
        
        // Tokens: content1 = {mit, license}, content2 = {mit, bsd, license}
        // Intersection: {mit, license} = 2
        // Magnitudes: sqrt(2 * 3) = sqrt(6) ≈ 2.449
        // Cosine: 2 / 2.449 * 100 ≈ 81.65
        let score = content1.cosine_similarity(&content2);
        assert!((score - 81.64965809277261).abs() < 0.01);
    }

    #[test]
    fn test_common_tokens() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD License".to_string());
        
        let common = content1.common_tokens(&content2);
        assert_eq!(common.len(), 2);
        assert!(common.contains("mit"));
        assert!(common.contains("license"));
    }

    #[test]
    fn test_union_tokens() {
        let content1 = Content::new("MIT License".to_string());
        let content2 = Content::new("MIT BSD".to_string());
        
        let union = content1.union_tokens(&content2);
        assert_eq!(union.len(), 3);
        assert!(union.contains("mit"));
        assert!(union.contains("license"));
        assert!(union.contains("bsd"));
    }

    #[test]
    fn test_from_conversions() {
        let content1 = Content::from("MIT License".to_string());
        let content2 = Content::from("MIT License");
        
        assert_eq!(content1.text(), content2.text());
        assert_eq!(content1.tokens(), content2.tokens());
    }

    #[test]
    fn test_display() {
        let content = Content::new("MIT License".to_string());
        assert_eq!(format!("{}", content), "MIT License");
    }

    #[test]
    fn test_is_empty() {
        let empty_content = Content::new("".to_string());
        let non_empty_content = Content::new("MIT".to_string());
        
        assert!(empty_content.is_empty());
        assert!(!non_empty_content.is_empty());
    }

    #[test]
    fn test_special_characters() {
        let content = Content::new("MIT/Apache-2.0 (dual license)".to_string());
        let tokens = content.tokens();
        
        // Should extract alphanumeric words and dots, ignoring other punctuation
        assert!(tokens.contains("mit"));
        assert!(tokens.contains("apache"));
        assert!(tokens.contains("2.0"));
        assert!(tokens.contains("dual"));
        assert!(tokens.contains("license"));
        assert!(!tokens.contains("/"));
        assert!(!tokens.contains("("));
        assert!(!tokens.contains(")"));
    }
}