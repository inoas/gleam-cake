import cake/types.{type Param}
import gleam/int
import gleam/list
import gleam/string

pub opaque type PreparedStatement {
  PreparedStatement(
    prefix: String,
    sql: String,
    params: List(Param),
    index: Int,
  )
}

pub fn new(prefix) {
  PreparedStatement(prefix, "", [], 0)
}

pub fn with_sql(prepared_statement: PreparedStatement, new_sql: String) {
  PreparedStatement(
    ..prepared_statement,
    sql: prepared_statement.sql <> new_sql,
  )
}

pub fn with_sql_and_param(
  prepared_statement: PreparedStatement,
  new_sql: String,
  new_param: Param,
) {
  PreparedStatement(
    ..prepared_statement,
    sql: prepared_statement.sql <> new_sql,
    params: list.append(prepared_statement.params, [new_param]),
    index: prepared_statement.index + 1,
  )
}

pub fn get_prefix(prepared_statement: PreparedStatement) -> String {
  prepared_statement.prefix
}

pub fn get_sql(prepared_statement: PreparedStatement) -> String {
  prepared_statement.sql
}

pub fn get_params(prepared_statement: PreparedStatement) -> List(Param) {
  prepared_statement.params
}

pub fn next_param(prepared_statement: PreparedStatement) -> String {
  prepared_statement.index
  |> int.add(1)
  |> int.to_string
  |> string.append(prepared_statement.prefix)
}
