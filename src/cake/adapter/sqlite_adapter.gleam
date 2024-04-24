import cake/prepared_statement.{type PreparedStatement}
import cake/query/select_query.{type SelectQuery}
import cake/query_builder

// import cake/stdlib/iox
import cake/param.{BoolParam, FloatParam, IntParam, NullParam, StringParam}
import gleam/list
import sqlight

pub fn to_prepared_statement(query: SelectQuery) -> PreparedStatement {
  query
  |> query_builder.build_select_prepared_statement("?")
}

pub fn with_memory_connection(callback_fun) {
  sqlight.with_connection(":memory:", callback_fun)
}

pub fn run_query(db_conn, query: SelectQuery, decoder) {
  let prp_stm = to_prepared_statement(query)
  // |> iox.dbg_label("prp_stm")

  let sql = prepared_statement.get_sql(prp_stm)
  // |> iox.dbg_label("sql")

  let params = prepared_statement.get_params(prp_stm)
  // |> iox.dbg_label("params")

  let db_params =
    params
    |> list.map(fn(param) {
      case param {
        BoolParam(param) -> sqlight.bool(param)
        FloatParam(param) -> sqlight.float(param)
        IntParam(param) -> sqlight.int(param)
        StringParam(param) -> sqlight.text(param)
        NullParam -> sqlight.null()
      }
    })
  // |> iox.dbg_label("db_params")

  sql
  |> sqlight.query(on: db_conn, with: db_params, expecting: decoder)
}

pub fn execute(query, conn) {
  query
  |> sqlight.exec(conn)
}
