import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/from as f
import cake/query/select as s
import cake/query/where as w
import pprint.{format as to_string}

fn query_where_between_setup() {
  f.table(name: "cats")
  |> s.new_from()
  |> s.where(w.col("age") |> w.between(w.int(10), w.int(20)))
}

pub fn query_where_between_builder_test() {
  query_where_between_setup()
  |> to_string
  |> birdie.snap("query_where_between_builder_test")
}

pub fn query_where_between_postgres_test() {
  query_where_between_setup()
  |> s.to_query
  |> postgres_adapter.to_prepared_statement
  |> to_string
  |> birdie.snap("query_where_between_postgres_test")
}

pub fn query_where_between_sqlite_test() {
  query_where_between_setup()
  |> s.to_query
  |> sqlite_adapter.to_prepared_statement
  |> to_string
  |> birdie.snap("query_where_between_sqlite_test")
}
