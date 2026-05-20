//// Supported Database Dialects
////

/// Cake generally supports 🐘PostgreSQL, 🪶SQLite, 🦭MariaDB, and 🐬MySQL.
///
/// NOTICE: A few features are not supported by all dialects.
///
pub type Dialect {
  Postgres
  Sqlite
  Maria
  Mysql
}

/// Returns the placeholder base for the given dialect.
///
pub fn placeholder_base(dialect dialect: Dialect) -> String {
  case dialect {
    Postgres -> "$"
    Sqlite -> "?"
    Maria -> "?"
    Mysql -> "?"
  }
}
