//// Sqlite dialect to be used in conjunction with the `sqlight` library.
////

import cake.{type CakeQuery}
import cake/internal/dialect.{Sqlite}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{type ReadQuery}
import cake/internal/write_query.{type WriteQuery}

/// Converts a cake query to a Sqlite prepared statement.
///
pub fn cake_query_to_prepared_statement(
  query qry: CakeQuery(a),
) -> PreparedStatement {
  qry |> cake.cake_query_to_prepared_statement(dialect: Sqlite)
}

/// Converts a (read) query to a Sqlite prepared statement.
///
pub fn query_to_prepared_statement(query qry: ReadQuery) -> PreparedStatement {
  qry |> cake.read_query_to_prepared_statement(dialect: Sqlite)
}

/// Converts a write query to a Sqlite prepared statement.
///
pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
) -> PreparedStatement {
  qry |> cake.write_query_to_prepared_statement(dialect: Sqlite)
}
