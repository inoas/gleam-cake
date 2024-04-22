import cake/query/select.{type SelectQuery}
import cake/query_builder
import cake/sql_types.{
  type PreparedStatement, BoolParam, FloatParam, IntParam, NullParam,
  StringParam,
}
import gleam/list
import pprint.{debug as dbg}
import sqlight

pub fn to_prepared_statement(query: SelectQuery) -> PreparedStatement {
  query
  |> query_builder.build_select_prepared_statement
}

pub fn with_memory_connection(callback_fun) {
  sqlight.with_connection(":memory:", callback_fun)
}

pub fn run_query(db_conn, query: SelectQuery, decoder) {
  let #(query, params) =
    query
    |> to_prepared_statement

  query
  |> dbg

  let sqlite_params =
    list.map(params, fn(param) {
      case param {
        BoolParam(param) -> sqlight.bool(param)
        FloatParam(param) -> sqlight.float(param)
        IntParam(param) -> sqlight.int(param)
        StringParam(param) -> sqlight.text(param)
        NullParam -> sqlight.null()
      }
    })
    |> dbg

  query
  |> sqlight.query(on: db_conn, with: sqlite_params, expecting: decoder)
}

pub fn execute(query, conn) {
  query
  |> dbg
  |> sqlight.exec(conn)
}
