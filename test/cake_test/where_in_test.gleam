import birdie
import cake/select as s
import cake/where as w
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

fn sub_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.where(w.col("name") |> w.eq(w.string("Karl")))
  |> s.to_query
}

fn where_in_query_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  // Regular IN
  |> s.where(w.col("age") |> w.in([w.int(1), w.int(2), w.int(3)]))
  // IN sub_query
  |> s.or_where(w.col("name") |> w.in_query(sub_query()))
  // IN sub_query could also work like such:
  |> s.or_where(w.col("name") |> w.in([w.string("Hello"), w.sub_query(sub_query())]))
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_in_query_test() {
  where_in_query_query()
  |> to_string
  |> birdie.snap("where_in_query_test")
}

pub fn where_in_query_prepared_statement_test() {
  let pgo = where_in_query_query() |> postgres.read_query_to_prepared_statement
  let lit = where_in_query_query() |> sqlite.read_query_to_prepared_statement
  let mdb = where_in_query_query() |> maria.read_query_to_prepared_statement
  let myq = where_in_query_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_query_prepared_statement_test")
}

pub fn where_in_query_execution_result_test() {
  let pgo = where_in_query_query() |> postgres_test_helper.setup_and_run
  let lit = where_in_query_query() |> sqlite_test_helper.setup_and_run
  let mdb = where_in_query_query() |> maria_test_helper.setup_and_run
  let myq = where_in_query_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_query_execution_result_test")
}
