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
  placeholder_base plchldr_bs: String,
  dialect db_adptr: Dialect,
) -> PreparedStatement {
  plchldr_bs
  |> PreparedStatement(sql: "", params: [], index: 0, dialect: db_adptr)
}

/// Append a parameter to the prepared statement SQL and
/// to the parameters list.
///
pub fn append_param(
  prepared_statement prp_stm: PreparedStatement,
  param nw_prm: Param,
) {
  let new_sql = prp_stm |> next_placeholder(prp_stm.dialect)
  prp_stm |> append_sql_and_param(new_sql, nw_prm)
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
  prepared_statement prp_stm: PreparedStatement,
  sql nw_sql: String,
) {
  PreparedStatement(..prp_stm, sql: prp_stm.sql <> nw_sql)
}

/// Get the prefix of the prepared statement.
///
pub fn get_prefix(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.prefix
}

/// Get the SQL of the prepared statement.
///
pub fn get_sql(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.sql
}

/// Get the parameters of the prepared statement.
///
pub fn get_params(prepared_statement prp_stm: PreparedStatement) -> List(Param) {
  prp_stm.params
}

/// Get the dialect of the prepared statement.
///
pub fn get_dialect(prepared_statement prp_stm: PreparedStatement) -> Dialect {
  prp_stm.dialect
}

/// Append SQL and a parameter to the prepared statement.
///
fn append_sql_and_param(
  prepared_statement prp_stm: PreparedStatement,
  sql nw_sql: String,
  param nw_prm: Param,
) {
  prp_stm |> append_sql_and_params(sql: nw_sql, params: [nw_prm])
}

/// Append SQL and parameters to the prepared statement.
///
fn append_sql_and_params(
  prepared_statement prp_stm: PreparedStatement,
  sql nw_sql: String,
  params nw_prms: List(Param),
) {
  PreparedStatement(
    ..prp_stm,
    sql: prp_stm.sql <> nw_sql,
    params: prp_stm.params |> list.append(nw_prms),
    index: prp_stm.index + list.length(nw_prms),
  )
}

fn next_placeholder(
  prepared_statement prp_stm: PreparedStatement,
  dialect dlct: Dialect,
) -> String {
  case dlct {
    Postgres | Sqlite ->
      prp_stm.prefix <> prp_stm.index |> int.add(1) |> int.to_string
    Maria | Mysql -> prp_stm.prefix
  }
}
// Maybe it is enough for this to be hidden in an internal module?
//
// TODO v3
// This should ONLY be used for debugging purposes
// not to ever run actual queries in production.
// pub fn to_debug(prepared_statement prp_stm: PreparedStatement) -> String {
// }
