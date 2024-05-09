import cake/internal/query.{type Query}
import cake/param.{type Param, BoolParam, FloatParam, IntParam, StringParam}
import cake/prepared_statement.{type PreparedStatement}
import cake/stdlib/iox
import gleam/list
import sqlight.{type Value}

pub fn to_prepared_statement(query qry: Query) -> PreparedStatement {
  qry |> query.builder_new("?")
}

pub fn with_memory_connection(callback_fun) {
  sqlight.with_connection(":memory:", callback_fun)
}

pub fn run_query(db_connection db_conn, query qry: Query, decoder dcdr) {
  let prp_stm = to_prepared_statement(qry)

  let sql =
    prepared_statement.get_sql(prp_stm)
    |> iox.dbg

  let params = prepared_statement.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> sqlight.bool(param)
        FloatParam(param) -> sqlight.float(param)
        IntParam(param) -> sqlight.int(param)
        StringParam(param) -> sqlight.text(param)
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.dbg

  sql
  |> sqlight.query(on: db_conn, with: db_params, expecting: dcdr)
}

pub fn execute(query: String, conn) {
  query |> sqlight.exec(conn)
}
