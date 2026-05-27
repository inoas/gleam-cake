//// Prepared Statements protect against SQL injection attacks by ensuring
//// that any parameters passed to the database are treated as escaped
//// values rather than raw SQL.
////

import cake/internal/dialect.{type Dialect, Maria, Mysql, Postgres, Sqlite}
import cake/param.{type Param}
import gleam/int
import gleam/list

/// A prepared statement is a SQL query with placeholders for parameters.
///
/// The parameters are then passed to the database adapter to be escaped
/// and inserted into the query.
///
pub opaque type PreparedStatement {
  PreparedStatement(
    prefix: String,
    sql: String,
    params: List(Param),
    index: Int,
    dialect: Dialect,
  )
}

/// Create a new prepared statement.
///
pub fn new(
  placeholder_base placeholder_base: String,
  dialect dialect: Dialect,
) -> PreparedStatement {
  placeholder_base
  |> PreparedStatement(sql: "", params: [], index: 0, dialect:)
}

/// Append a parameter to the prepared statement SQL and
/// to the parameters list.
///
pub fn append_param(
  prepared_statement prepared_statement: PreparedStatement,
  param param: Param,
) {
  let sql =
    prepared_statement |> next_placeholder(dialect: prepared_statement.dialect)
  prepared_statement |> append_sql_and_param(sql:, param:)
}

/// Appends arbitrary SQL to the prepared statement.
///
/// ⛔ ⛔ ⛔
///
/// WARNING: YOU ARE FORBIDDEN TO INSERT UNCONTROLLED USER INPUT THIS WAY!
///
/// ⛔ ⛔ ⛔
///
pub fn append_sql(
  prepared_statement prepared_statement: PreparedStatement,
  sql new_sql: String,
) {
  PreparedStatement(
    ..prepared_statement,
    sql: prepared_statement.sql <> new_sql,
  )
}

/// Get the prefix of the prepared statement.
///
pub fn get_prefix(
  prepared_statement prepared_statement: PreparedStatement,
) -> String {
  prepared_statement.prefix
}

/// Get the SQL of the prepared statement.
///
pub fn get_sql(
  prepared_statement prepared_statement: PreparedStatement,
) -> String {
  prepared_statement.sql
}

/// Get the parameters of the prepared statement.
///
pub fn get_params(
  prepared_statement prepared_statement: PreparedStatement,
) -> List(Param) {
  prepared_statement.params
}

/// Get the dialect of the prepared statement.
///
pub fn get_dialect(
  prepared_statement prepared_statement: PreparedStatement,
) -> Dialect {
  prepared_statement.dialect
}

/// Append SQL and a parameter to the prepared statement.
///
fn append_sql_and_param(
  prepared_statement prepared_statement: PreparedStatement,
  sql sql: String,
  param param: Param,
) {
  prepared_statement |> append_sql_and_params(sql:, params: [param])
}

/// Append SQL and parameters to the prepared statement.
///
fn append_sql_and_params(
  prepared_statement prepared_statement: PreparedStatement,
  sql sql: String,
  params params: List(Param),
) {
  PreparedStatement(
    ..prepared_statement,
    sql: prepared_statement.sql <> sql,
    params: prepared_statement.params |> list.append(params),
    index: prepared_statement.index + list.length(params),
  )
}

fn next_placeholder(
  prepared_statement prepared_statement: PreparedStatement,
  dialect dialect: Dialect,
) -> String {
  case dialect {
    Postgres | Sqlite ->
      prepared_statement.prefix
      <> prepared_statement.index |> int.add(1) |> int.to_string
    Maria | Mysql -> prepared_statement.prefix
  }
}
// Maybe it is enough for this to be hidden in an internal module?
//
// TODO v3
// This should ONLY be used for debugging purposes
// not to ever run actual queries in production.
// pub fn to_debug(prepared_statement prp_stm: PreparedStatement) -> String {
// }
