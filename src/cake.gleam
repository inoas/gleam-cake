//// *Cake* is an SQL query building library for RDBMS:
////
//// - 🐘PostgreSQL
//// - 🪶SQLite
//// - 🦭MariaDB
//// - 🐬MySQL
////
//// For examples see the tests.
////

import cake/internal/dialect
import cake/internal/prepared_statement
import cake/internal/read_query
import cake/internal/write_query
import cake/param.{type Param}
import gleam/io

pub type ReadQuery =
  read_query.ReadQuery

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

pub type Dialect =
  dialect.Dialect

pub type PreparedStatement =
  prepared_statement.PreparedStatement

/// Base wrapper query type to be able to pass around read and write queries in
/// the same way.
///
pub type CakeQuery(a) {
  CakeReadQuery(ReadQuery)
  CakeWriteQuery(WriteQuery(a))
}

/// Create a Cake read query from a read query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_read_query(query qry: ReadQuery) -> CakeQuery(a) {
  qry |> CakeReadQuery
}

/// Create a Cake write query from a write query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_write_query(query qry: WriteQuery(a)) -> CakeQuery(a) {
  qry |> CakeWriteQuery
}

/// Create a prepared statement from a Cake query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_prepared_statement(
  query qry: CakeQuery(a),
  dialect dlct: Dialect,
) -> PreparedStatement {
  case qry {
    CakeReadQuery(rd_qry) ->
      rd_qry
      |> read_query_to_prepared_statement(dialect: dlct)
    CakeWriteQuery(wt_qry) ->
      wt_qry
      |> write_query_to_prepared_statement(dialect: dlct)
  }
}

/// Create a prepared statement from a read query.
///
pub fn read_query_to_prepared_statement(
  query qry: ReadQuery,
  dialect dlct: Dialect,
) -> PreparedStatement {
  dlct
  |> dialect.placeholder_base
  |> read_query.to_prepared_statement(query: qry, dialect: dlct)
}

/// Create a prepared statement from a write query.
///
pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
  dialect dlct: Dialect,
) -> PreparedStatement {
  dlct
  |> dialect.placeholder_base
  |> write_query.to_prepared_statement(query: qry, dialect: dlct)
}

/// Get the SQL of the prepared statement.
///
pub fn get_sql(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm |> prepared_statement.get_sql
}

/// Get the parameters of the prepared statement.
///
pub fn get_params(prepared_statement prp_stm: PreparedStatement) -> List(Param) {
  prp_stm |> prepared_statement.get_params
}

/// As a library *Cake* cannot be invoked directly in a meaningful way.
///
pub fn main() {
  {
    "\n"
    <> "cake is a query building library and cannot be invoked directly."
    <> "\n"
    <> "For demos see the tests."
  }
  |> io.println
}
