//// Prepared Statements protect against SQL injection attacks by ensuring
//// that any parameters passed to the database are treated as escaped
//// values rather than raw SQL.
////

import cake/dialect.{type Dialect}
import cake/param.{type Param}
import gleam/int
import gleam/list

pub opaque type PreparedStatement {
  PreparedStatement(
    prefix: String,
    sql: String,
    params: List(Param),
    index: Int,
    dialect: Dialect,
  )
}

pub fn new(prefix prfx: String, dialect db_adptr: Dialect) -> PreparedStatement {
  prfx |> PreparedStatement(sql: "", params: [], index: 0, dialect: db_adptr)
}

pub fn append_param(
  prepared_statement prp_stm: PreparedStatement,
  param nw_prm: Param,
) {
  let new_sql = prp_stm |> next_placeholder
  prp_stm |> append_sql_and_param(new_sql, nw_prm)
}

pub fn append_sql(
  prepared_statement prp_stm: PreparedStatement,
  sql nw_sql: String,
) {
  PreparedStatement(..prp_stm, sql: prp_stm.sql <> nw_sql)
}

pub fn get_prefix(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.prefix
}

pub fn get_sql(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.sql
}

pub fn get_params(prepared_statement prp_stm: PreparedStatement) -> List(Param) {
  prp_stm.params
}

pub fn get_dialect(prepared_statement prp_stm: PreparedStatement) -> Dialect {
  prp_stm.dialect
}

fn append_sql_and_param(
  prepared_statement prp_stm: PreparedStatement,
  sql nw_sql: String,
  param nw_prm: Param,
) {
  prp_stm |> append_sql_and_params(sql: nw_sql, params: [nw_prm])
}

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

fn next_placeholder(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.prefix <> prp_stm.index |> int.add(1) |> int.to_string
}
//
// TODO
// This should ONLY be used for debugging purposes
// not to ever run actual queries in production.
// pub fn to_debug(prepared_statement prp_stm: PreparedStatement) -> String {
// }
