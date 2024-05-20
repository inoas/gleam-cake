import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/internal/query as q
import cake/query/from as f
import cake/query/select as s
import cake/query/where as w
import pprint

fn query_where_between_setup() {
  f.table(name: "cats")
  |> s.new_from()
  |> s.where(w.col("age") |> w.between(w.int(10), w.int(20)))
}

pub fn query_where_between_builder_test() {
  query_where_between_setup()
  |> pprint.format
  |> birdie.snap("query_where_between_builder_test")
}

pub fn query_where_between_postgres_test() {
  query_where_between_setup()
  |> q.query_select_wrap
  |> postgres_adapter.to_prepared_statement
  |> pprint.format
  |> birdie.snap("query_where_between_postgres_test")
}

pub fn query_where_between_sqlite_test() {
  query_where_between_setup()
  |> q.query_select_wrap
  |> sqlite_adapter.to_prepared_statement
  |> pprint.format
  |> birdie.snap("query_where_between_sqlite_test")
}
