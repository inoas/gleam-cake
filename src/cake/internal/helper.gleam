//// Helper functions
////
//// TODO v2: Think about if this makes any sense for v2
////

// TODO v2 escaped_identifier, quote and escape table and column names

/// Returns a callable that creates a qualified identifier
///
pub fn qualified_identifier(scope scp: String) -> fn(String) -> String {
  fn(identifier) -> String { scp <> "." <> identifier }
}
