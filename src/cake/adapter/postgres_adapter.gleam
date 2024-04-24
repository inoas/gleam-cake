import cake/prepared_statement.{type PreparedStatement}
import cake/query/select.{type SelectQuery}
import cake/query_builder

// import cake/stdlib/iox
import cake/types.{BoolParam, FloatParam, IntParam, NullParam, StringParam}
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection}

pub fn to_prepared_statement(query: SelectQuery) -> PreparedStatement {
  query
  |> query_builder.build_select_prepared_statement("$")
}

pub fn with_connection(f: fn(Connection) -> a) -> a {
  let connection =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "gleam_cake",
      ),
    )

  let value = f(connection)
  let assert Nil = pgo.disconnect(connection)
  value
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
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })
  // |> iox.dbg_label("db_params")

  let result =
    sql
    |> pgo.execute(on: db_conn, with: db_params, expecting: decoder)

  case result {
    Ok(pgo.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

pub fn execute(query, conn) {
  let execute_decoder = dynamic.dynamic

  query
  |> pgo.execute(conn, with: [], expecting: execute_decoder)
}
