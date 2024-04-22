import cake/query/select.{type SelectQuery}
import cake/query_builder
import pprint.{debug as dbg}
import sqlight

pub fn to_sql(query: SelectQuery) -> String {
  query
  |> query_builder.build_select_sql
}

pub fn with_memory_connection(callback_fun) {
  sqlight.with_connection(":memory:", callback_fun)
}

pub fn run_query(db_conn, query: SelectQuery, decoder) {
  query
  |> to_sql
  |> dbg
  |> sqlight.query(on: db_conn, with: [], expecting: decoder)
}

pub fn execute(query, conn) {
  query
  |> dbg
  |> sqlight.exec(conn)
}
