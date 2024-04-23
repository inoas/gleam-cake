import cake/query/select.{type SelectQuery}
import cake/query_builder
import cake/types.{
  type PreparedStatement, BoolParam, FloatParam, IntParam, NullParam,
  StringParam,
}
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/pgo.{type Connection}
import pprint.{debug as dbg}

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
  let #(query, params) =
    query
    |> to_prepared_statement

  query
  |> dbg

  let pgo_params =
    list.map(params, fn(param) {
      case param {
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })
    |> dbg

  query
  |> pgo.execute(on: db_conn, with: pgo_params, expecting: decoder)
}

pub fn execute(query, conn) {
  let execute_decoder = fn(d: Dynamic) { Ok(d) }

  query
  |> pgo.execute(conn, with: [], expecting: execute_decoder)
}
