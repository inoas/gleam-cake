import cake/internal/query.{type Query}
import cake/param.{type Param, BoolParam, FloatParam, IntParam, StringParam}
import cake/prepared_statement.{type PreparedStatement}
import cake/stdlib/iox
import gleam/dynamic
import gleam/list
import gleam/pgo.{type Connection, type Value}

const prepared_statement_placeholder_prefix = "$"

pub fn to_prepared_statement(query qry: Query) -> PreparedStatement {
  qry |> query.builder_new(prepared_statement_placeholder_prefix)
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
  pgo.disconnect(connection)

  value
}

pub fn run_query(db_conn, query qry: Query, decoder dcdr) {
  let prp_stm = to_prepared_statement(qry)

  let sql =
    prepared_statement.get_sql(prp_stm)
    |> iox.dbg

  let params = prepared_statement.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        // NullParam -> pgo.null()
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.dbg

  let result =
    sql
    |> pgo.execute(on: db_conn, with: db_params, expecting: dcdr)

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
