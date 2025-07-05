/// Tracks the best scoring match for license similarity
#[derive(Debug, Clone, PartialEq)]
pub struct Score {
    pub license_id: String,
    pub score: f64,
}

impl Score {
    /// Create a new Score with the given license ID and score
    pub fn new(license_id: String, score: f64) -> Self {
        Self { license_id, score }
    }

    /// Create a Score from string slice
    pub fn from_str(license_id: &str, score: f64) -> Self {
        Self::new(license_id.to_string(), score)
    }

    /// Get the license ID
    pub fn license_id(&self) -> &str {
        &self.license_id
    }

    /// Get the score
    pub fn score(&self) -> f64 {
        self.score
    }

    /// Check if this score is better (higher) than another
    pub fn is_better_than(&self, other: &Score) -> bool {
        self.score > other.score
    }

    /// Check if this score meets or exceeds a threshold
    pub fn meets_threshold(&self, threshold: f64) -> bool {
        self.score >= threshold
    }

    /// Update the score if the new score is better
    pub fn update_if_better(&mut self, license_id: String, score: f64) -> bool {
        if score > self.score {
            self.license_id = license_id;
            self.score = score;
            true
        } else {
            false
        }
    }

    /// Create a zero score (useful for initialization)
    pub fn zero() -> Self {
        Self::new("unknown".to_string(), 0.0)
    }

    /// Check if this is a zero score
    pub fn is_zero(&self) -> bool {
        self.score == 0.0
    }

    /// Check if this score indicates a perfect match
    pub fn is_perfect(&self) -> bool {
        (self.score - 100.0).abs() < f64::EPSILON
    }

    /// Get score as a percentage string
    pub fn as_percentage(&self) -> String {
        format!("{:.1}%", self.score)
    }
}

impl Default for Score {
    fn default() -> Self {
        Self::zero()
    }
}

impl std::fmt::Display for Score {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: {:.1}%", self.license_id, self.score)
    }
}

impl PartialOrd for Score {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        self.score.partial_cmp(&other.score)
    }
}

impl From<(String, f64)> for Score {
    fn from((license_id, score): (String, f64)) -> Self {
        Self::new(license_id, score)
    }
}

impl From<(&str, f64)> for Score {
    fn from((license_id, score): (&str, f64)) -> Self {
        Self::from_str(license_id, score)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_score_creation() {
        let score = Score::new("MIT".to_string(), 85.5);
        assert_eq!(score.license_id(), "MIT");
        assert_eq!(score.score(), 85.5);
    }

    #[test]
    fn test_from_str() {
        let score = Score::from_str("Apache-2.0", 90.0);
        assert_eq!(score.license_id(), "Apache-2.0");
        assert_eq!(score.score(), 90.0);
    }

    #[test]
    fn test_is_better_than() {
        let score1 = Score::new("MIT".to_string(), 85.0);
        let score2 = Score::new("Apache-2.0".to_string(), 90.0);
        let score3 = Score::new("BSD".to_string(), 80.0);

        assert!(score2.is_better_than(&score1));
        assert!(score1.is_better_than(&score3));
        assert!(!score1.is_better_than(&score2));
    }

    #[test]
    fn test_meets_threshold() {
        let score = Score::new("MIT".to_string(), 85.0);
        
        assert!(score.meets_threshold(80.0));
        assert!(score.meets_threshold(85.0));
        assert!(!score.meets_threshold(90.0));
    }

    #[test]
    fn test_update_if_better() {
        let mut score = Score::new("MIT".to_string(), 80.0);
        
        // Better score should update
        assert!(score.update_if_better("Apache-2.0".to_string(), 90.0));
        assert_eq!(score.license_id(), "Apache-2.0");
        assert_eq!(score.score(), 90.0);
        
        // Worse score should not update
        assert!(!score.update_if_better("BSD".to_string(), 85.0));
        assert_eq!(score.license_id(), "Apache-2.0");
        assert_eq!(score.score(), 90.0);
        
        // Equal score should not update
        assert!(!score.update_if_better("GPL".to_string(), 90.0));
        assert_eq!(score.license_id(), "Apache-2.0");
        assert_eq!(score.score(), 90.0);
    }

    #[test]
    fn test_zero_score() {
        let score = Score::zero();
        assert_eq!(score.license_id(), "unknown");
        assert_eq!(score.score(), 0.0);
        assert!(score.is_zero());
        assert!(!score.is_perfect());
    }

    #[test]
    fn test_default() {
        let score = Score::default();
        assert_eq!(score.license_id(), "unknown");
        assert_eq!(score.score(), 0.0);
        assert!(score.is_zero());
    }

    #[test]
    fn test_is_perfect() {
        let perfect_score = Score::new("MIT".to_string(), 100.0);
        let imperfect_score = Score::new("Apache-2.0".to_string(), 99.9);
        
        assert!(perfect_score.is_perfect());
        assert!(!imperfect_score.is_perfect());
    }

    #[test]
    fn test_as_percentage() {
        let score = Score::new("MIT".to_string(), 85.6789);
        assert_eq!(score.as_percentage(), "85.7%");
    }

    #[test]
    fn test_display() {
        let score = Score::new("MIT".to_string(), 85.6);
        assert_eq!(format!("{}", score), "MIT: 85.6%");
    }

    #[test]
    fn test_partial_ord() {
        let score1 = Score::new("MIT".to_string(), 80.0);
        let score2 = Score::new("Apache-2.0".to_string(), 90.0);
        let score3 = Score::new("BSD".to_string(), 80.0);

        assert!(score2 > score1);
        assert!(score1 < score2);
        assert!(score1 == score3); // Note: PartialEq compares both fields, PartialOrd only score
    }

    #[test]
    fn test_from_tuple() {
        let score1 = Score::from(("MIT".to_string(), 85.0));
        let score2 = Score::from(("Apache-2.0", 90.0));
        
        assert_eq!(score1.license_id(), "MIT");
        assert_eq!(score1.score(), 85.0);
        
        assert_eq!(score2.license_id(), "Apache-2.0");
        assert_eq!(score2.score(), 90.0);
    }

    #[test]
    fn test_edge_cases() {
        let zero_score = Score::new("Zero".to_string(), 0.0);
        let negative_score = Score::new("Negative".to_string(), -10.0);
        let over_hundred = Score::new("Over".to_string(), 150.0);
        
        assert!(zero_score.is_zero());
        assert!(!negative_score.is_zero());
        assert!(!over_hundred.is_perfect());
        
        assert!(over_hundred.is_better_than(&zero_score));
        assert!(!negative_score.meets_threshold(0.0));
    }
}