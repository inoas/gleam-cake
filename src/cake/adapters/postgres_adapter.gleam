import cake/query/select.{type SelectQuery}
import cake/query_builder
import gleam/dynamic.{type Dynamic}
import gleam/pgo
import pprint.{debug as dbg}

pub fn to_sql(query: SelectQuery) -> String {
  query
  |> query_builder.build_select_sql
}

pub fn with_memory_connection(callback_fun) {
  let db_conn =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "gleam_cake",
        pool_size: 15,
      ),
    )

  callback_fun(db_conn)

  pgo.disconnect(db_conn)
}

pub fn run_query(db_conn, query: SelectQuery, decoder) {
  query
  |> to_sql
  |> dbg
  |> pgo.execute(on: db_conn, with: [], expecting: decoder)
}

pub fn execute(query, conn) {
  let execute_decoder = fn(d: Dynamic) { Ok(d) }

  query
  |> dbg
  |> pgo.execute(conn, with: [], expecting: execute_decoder)
}
