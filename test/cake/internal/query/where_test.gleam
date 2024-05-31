import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as s
import cake/query/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

fn where_query() {
  f.table(name: "cats")
  |> s.new_from
  |> s.where(w.col("age") |> w.eq(w.int(10)))
  |> s.where(w.fragment(frgmt.literal("1 = 1")))
  |> s.where(w.string("Hello") |> w.eq(w.col("name")))
  |> s.to_query
}

pub fn where_test() {
  let expected_pgo = where_query()
  let expected_sql = where_query()

  #(expected_pgo, expected_sql)
  |> to_string
  |> birdie.snap("where_test")
}

pub fn where_prepared_statement_test() {
  let expected_pgo = where_query() |> postgres_adapter.to_prepared_statement
  let expected_sql = where_query() |> sqlite_adapter.to_prepared_statement

  #(expected_pgo, expected_sql)
  |> to_string
  |> birdie.snap("where_prepared_statement_test")
}

pub fn where_execution_result_test() {
  let expected_pgo = where_query() |> postgres_test_helper.setup_and_run
  let expected_sql = where_query() |> sqlite_test_helper.setup_and_run

  where_query()
  #(expected_pgo, expected_sql)
  |> to_string
  |> birdie.snap("where_execution_result_test")
}
