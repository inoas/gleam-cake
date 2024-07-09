//// Supported Database Dialects
////

/// Cake supports Postgres, SQLite MariaDB and MySQL,
///
/// A few features are not supported by all dialects.
///
pub type Dialect {
  Postgres
  Sqlite
  Maria
  Mysql
}

/// Returns the placeholder base for the given dialect.
///
pub fn placeholder_base(dialect dlct: Dialect) -> String {
  case dlct {
    Postgres -> "$"
    Sqlite -> "?"
    Maria -> "?"
    Mysql -> "?"
  }
}
