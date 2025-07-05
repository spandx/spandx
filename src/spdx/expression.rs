use crate::spdx::license::LicenseTree;
use pest::Parser;
use pest_derive::Parser;

#[derive(Parser)]
#[grammar = "spdx/expression.pest"]
pub struct ExpressionParser;

pub type Expression = LicenseTree;

impl ExpressionParser {
    pub fn new() -> Self {
        Self
    }

    pub fn parse(&self, input: &str) -> Result<LicenseTree, String> {
        let pairs = <Self as Parser<Rule>>::parse(Rule::expression, input)
            .map_err(|e| format!("Parse error: {}", e))?;
        
        for pair in pairs {
            return self.parse_expression(pair);
        }
        
        Err("No valid expression found".to_string())
    }

    fn parse_expression(&self, pair: pest::iterators::Pair<Rule>) -> Result<LicenseTree, String> {
        match pair.as_rule() {
            Rule::expression => {
                let mut inner = pair.into_inner();
                if let Some(expr) = inner.next() {
                    self.parse_expression(expr)
                } else {
                    Err("Empty expression".to_string())
                }
            }
            Rule::or_expression => {
                let mut inner = pair.into_inner();
                let mut left = self.parse_expression(inner.next().ok_or("Missing left operand")?)?;
                
                while let Some(op) = inner.next() {
                    if op.as_rule() == Rule::or_op {
                        let right = self.parse_expression(inner.next().ok_or("Missing right operand")?)?;
                        left = LicenseTree::Binary {
                            left: Box::new(left),
                            op: "OR".to_string(),
                            right: Box::new(right),
                        };
                    }
                }
                
                Ok(left)
            }
            Rule::and_expression => {
                let mut inner = pair.into_inner();
                let mut left = self.parse_expression(inner.next().ok_or("Missing left operand")?)?;
                
                while let Some(op) = inner.next() {
                    if op.as_rule() == Rule::and_op {
                        let right = self.parse_expression(inner.next().ok_or("Missing right operand")?)?;
                        left = LicenseTree::Binary {
                            left: Box::new(left),
                            op: "AND".to_string(),
                            right: Box::new(right),
                        };
                    }
                }
                
                Ok(left)
            }
            Rule::with_expression => {
                let mut inner = pair.into_inner();
                let license = self.parse_expression(inner.next().ok_or("Missing license in WITH expression")?)?;
                
                if let Some(with_op) = inner.next() {
                    if with_op.as_rule() == Rule::with_op {
                        let exception = inner.next().ok_or("Missing exception in WITH expression")?;
                        Ok(LicenseTree::With {
                            license: Box::new(license),
                            exception: exception.as_str().to_string(),
                        })
                    } else {
                        Ok(license)
                    }
                } else {
                    Ok(license)
                }
            }
            Rule::primary => {
                let mut inner = pair.into_inner();
                if let Some(expr) = inner.next() {
                    self.parse_expression(expr)
                } else {
                    Err("Empty primary expression".to_string())
                }
            }
            Rule::parenthesized_expression => {
                let mut inner = pair.into_inner();
                if let Some(expr) = inner.next() {
                    Ok(LicenseTree::Parenthesized(Box::new(self.parse_expression(expr)?)))
                } else {
                    Err("Empty parenthesized expression".to_string())
                }
            }
            Rule::license_id => {
                Ok(LicenseTree::License(pair.as_str().to_string()))
            }
            Rule::license_ref => {
                Ok(LicenseTree::License(pair.as_str().to_string()))
            }
            Rule::exception_id => {
                Ok(LicenseTree::License(pair.as_str().to_string()))
            }
            _ => Err(format!("Unexpected rule: {:?}", pair.as_rule())),
        }
    }
}

impl Default for ExpressionParser {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_license() {
        let parser = ExpressionParser::new();
        let result = parser.parse("MIT").unwrap();
        
        match result {
            LicenseTree::License(id) => assert_eq!(id, "MIT"),
            _ => panic!("Expected simple license"),
        }
    }

    #[test]
    fn test_binary_and_expression() {
        let parser = ExpressionParser::new();
        let result = parser.parse("MIT AND Apache-2.0");
        
        match result {
            Ok(tree) => {
                // println!("Parsed tree: {:?}", tree);
                match tree {
                    LicenseTree::Binary { left, op, right } => {
                        assert_eq!(op, "AND");
                        match (left.as_ref(), right.as_ref()) {
                            (LicenseTree::License(l), LicenseTree::License(r)) => {
                                assert_eq!(l, "MIT");
                                assert_eq!(r, "Apache-2.0");
                            }
                            _ => panic!("Expected license operands, got: {:?} and {:?}", left, right),
                        }
                    }
                    _ => panic!("Expected binary expression, got: {:?}", tree),
                }
            }
            Err(e) => panic!("Parse error: {}", e),
        }
    }

    #[test]
    fn test_binary_or_expression() {
        let parser = ExpressionParser::new();
        let result = parser.parse("MIT OR Apache-2.0").unwrap();
        
        match result {
            LicenseTree::Binary { left, op, right } => {
                assert_eq!(op, "OR");
                match (left.as_ref(), right.as_ref()) {
                    (LicenseTree::License(l), LicenseTree::License(r)) => {
                        assert_eq!(l, "MIT");
                        assert_eq!(r, "Apache-2.0");
                    }
                    _ => panic!("Expected license operands"),
                }
            }
            _ => panic!("Expected binary expression"),
        }
    }

    #[test]
    fn test_with_expression() {
        let parser = ExpressionParser::new();
        let result = parser.parse("GPL-2.0 WITH Classpath-exception-2.0").unwrap();
        
        match result {
            LicenseTree::With { license, exception } => {
                assert_eq!(exception, "Classpath-exception-2.0");
                match license.as_ref() {
                    LicenseTree::License(id) => assert_eq!(id, "GPL-2.0"),
                    _ => panic!("Expected license in WITH expression"),
                }
            }
            _ => panic!("Expected WITH expression"),
        }
    }

    #[test]
    fn test_parenthesized_expression() {
        let parser = ExpressionParser::new();
        let result = parser.parse("(MIT OR Apache-2.0)").unwrap();
        
        match result {
            LicenseTree::Parenthesized(inner) => {
                match inner.as_ref() {
                    LicenseTree::Binary { op, .. } => assert_eq!(op, "OR"),
                    _ => panic!("Expected binary expression in parentheses"),
                }
            }
            _ => panic!("Expected parenthesized expression"),
        }
    }

    #[test]
    fn test_complex_expression() {
        let parser = ExpressionParser::new();
        let result = parser.parse("MIT AND (Apache-2.0 OR GPL-3.0)").unwrap();
        
        match result {
            LicenseTree::Binary { left, op, right } => {
                assert_eq!(op, "AND");
                match (left.as_ref(), right.as_ref()) {
                    (LicenseTree::License(l), LicenseTree::Parenthesized(inner)) => {
                        assert_eq!(l, "MIT");
                        match inner.as_ref() {
                            LicenseTree::Binary { op, .. } => assert_eq!(op, "OR"),
                            _ => panic!("Expected OR in parentheses"),
                        }
                    }
                    _ => panic!("Expected license and parenthesized expression"),
                }
            }
            _ => panic!("Expected complex binary expression"),
        }
    }

    #[test]
    fn test_license_ref() {
        let parser = ExpressionParser::new();
        let result = parser.parse("LicenseRef-Custom").unwrap();
        
        match result {
            LicenseTree::License(id) => assert_eq!(id, "LicenseRef-Custom"),
            _ => panic!("Expected license reference"),
        }
    }

    #[test]
    fn test_case_insensitive_operators() {
        let parser = ExpressionParser::new();
        let result = parser.parse("MIT and Apache-2.0").unwrap();
        
        match result {
            LicenseTree::Binary { op, .. } => assert_eq!(op, "AND"),
            _ => panic!("Expected binary expression with normalized operator"),
        }
    }
}