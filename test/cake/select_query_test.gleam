import birdie
import cake/adapter/postgres
import cake/adapter/sqlite
import cake/query/from as f
import cake/query/join as j
import cake/query/select as s
import cake/query/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

pub fn select_query_query() {
  s.new()
  |> s.from(f.table("cats"))
  |> s.select([s.col("cats.name")])
  |> s.join(j.cross(with: j.table("owners"), alias: "owners"))
  |> s.where(w.col("owners.name") |> w.like("%i%"))
  |> s.group_by("cats.name")
  |> s.having(w.col("cats.name") |> w.like("%i%"))
  |> s.order_asc("cats.name")
  |> s.limit(10)
  |> s.offset(1)
  |> s.epilog("-- my epilog comment here")
  |> s.to_query
}

pub fn select_query_test() {
  select_query_query()
  |> to_string
  |> birdie.snap("select_query_test")
}

pub fn select_query_prepared_statement_test() {
  let pgo = select_query_query() |> postgres.to_prepared_statement
  let lit = select_query_query() |> sqlite.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_query_prepared_statement_test")
}

pub fn select_query_execution_result_test() {
  let pgo = select_query_query() |> postgres_test_helper.setup_and_run
  let lit = select_query_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_query_execution_result_test")
}
