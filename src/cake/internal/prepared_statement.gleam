import cake/param.{type Param}
import gleam/int
import gleam/list

pub opaque type PreparedStatement {
  PreparedStatement(
    prefix: String,
    sql: String,
    params: List(Param),
    index: Int,
  )
}

pub fn new(prefix prfx: String) -> PreparedStatement {
  prfx |> PreparedStatement("", [], 0)
}

pub fn append_sql(
  prepared_statement prp_stm: PreparedStatement,
  new_sql nw_sql: String,
) {
  PreparedStatement(..prp_stm, sql: prp_stm.sql <> nw_sql)
}

pub fn append_sql_and_param(
  prepared_statement prp_stm: PreparedStatement,
  new_sql nw_sql: String,
  new_param nw_prms: Param,
) {
  PreparedStatement(
    ..prp_stm,
    sql: prp_stm.sql <> nw_sql,
    params: list.append(prp_stm.params, [nw_prms]),
    index: prp_stm.index + 1,
  )
}

pub fn append_sql_and_params(
  prepared_statement prp_stm: PreparedStatement,
  new_sql nw_sql: String,
  new_params nw_prms: List(Param),
) {
  PreparedStatement(
    ..prp_stm,
    sql: prp_stm.sql <> nw_sql,
    params: list.append(prp_stm.params, nw_prms),
    index: prp_stm.index + list.length(nw_prms),
  )
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

pub fn next_placeholder(prepared_statement prp_stm: PreparedStatement) -> String {
  prp_stm.prefix <> prp_stm.index |> int.add(1) |> int.to_string
}
