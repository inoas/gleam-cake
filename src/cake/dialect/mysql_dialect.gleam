//// MySQL dialect to be used in conjunction with the `gmysql` library.
////

import cake.{type CakeQuery}
import cake/internal/dialect.{Mysql}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{type ReadQuery}
import cake/internal/write_query.{type WriteQuery}

/// Converts a cake query to a MySQL prepared statement.
///
pub fn cake_query_to_prepared_statement(
  query qry: CakeQuery(a),
) -> PreparedStatement {
  qry |> cake.cake_query_to_prepared_statement(dialect: Mysql)
}

/// Converts a (read) query to a MySQL prepared statement.
///
pub fn query_to_prepared_statement(query qry: ReadQuery) -> PreparedStatement {
  qry |> cake.read_query_to_prepared_statement(dialect: Mysql)
}

/// Converts a write query to a MySQL prepared statement.
///
pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
) -> PreparedStatement {
  qry |> cake.write_query_to_prepared_statement(dialect: Mysql)
}
