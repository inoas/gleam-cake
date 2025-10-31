import birdie
import cake/select as s
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn select_distinct_query() {
  s.new()
  |> s.from_table("cats")
  |> s.distinct
  |> s.selects([s.col("is_wild")])
  |> s.order_by_asc("is_wild")
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_distinct_test() {
  select_distinct_query()
  |> to_string
  |> birdie.snap("select_distinct_test")
}

pub fn select_distinct_prepared_statement_test() {
  let pgo = select_distinct_query() |> postgres.read_query_to_prepared_statement
  let lit = select_distinct_query() |> sqlite.read_query_to_prepared_statement
  let mdb = select_distinct_query() |> maria.read_query_to_prepared_statement
  let myq = select_distinct_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_distinct_prepared_statement_test")
}

pub fn select_distinct_execution_result_test() {
  let pgo = select_distinct_query() |> postgres_test_helper.setup_and_run
  let lit = select_distinct_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_distinct_query() |> maria_test_helper.setup_and_run
  let myq = select_distinct_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_distinct_execution_result_test")
}
