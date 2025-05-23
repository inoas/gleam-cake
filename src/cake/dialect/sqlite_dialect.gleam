//// 🪶SQLite dialect to be used in conjunction with the `sqlight` library.
////

import cake
import cake/internal/dialect.{Sqlite}
import cake/internal/prepared_statement
import cake/internal/read_query
import cake/internal/write_query

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ type re-exports                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub type CakeQuery(a) =
  cake.CakeQuery(a)

pub type PreparedStatement =
  prepared_statement.PreparedStatement

pub type ReadQuery =
  read_query.ReadQuery

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Converts a cake query to a 🪶SQLite prepared statement.
///
pub fn cake_query_to_prepared_statement(
  query qry: CakeQuery(a),
) -> PreparedStatement {
  qry |> cake.to_prepared_statement(dialect: Sqlite)
}

/// Converts read query to a 🪶SQLite prepared statement.
///
pub fn read_query_to_prepared_statement(
  query qry: ReadQuery,
) -> PreparedStatement {
  qry |> cake.read_query_to_prepared_statement(dialect: Sqlite)
}

/// Converts a write query to a 🪶SQLite prepared statement.
///
pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
) -> PreparedStatement {
  qry |> cake.write_query_to_prepared_statement(dialect: Sqlite)
}
