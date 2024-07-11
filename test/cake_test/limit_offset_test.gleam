import birdie
import cake/combined as c
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

fn limit_offset_query() {
  s.new()
  |> s.from_table("cats")
  |> s.order_by_asc("name")
  |> s.limit(4)
  |> s.offset(0)
}

fn select_query() {
  limit_offset_query()
  |> s.to_query
}

fn combined_query() {
  let limit_offset_query = limit_offset_query()
  limit_offset_query
  |> c.union_all(limit_offset_query)
  |> c.order_by_asc("name")
  |> c.limit(1)
  |> c.offset(2)
  |> c.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_limit_offset_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_limit_offset_test")
}

pub fn select_limit_offset_prepared_statement_test() {
  let pgo = select_query() |> postgres.read_query_to_prepared_statement
  let lit = select_query() |> sqlite.read_query_to_prepared_statement
  let mdb = select_query() |> maria.read_query_to_prepared_statement
  let myq = select_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_limit_offset_prepared_statement_test")
}

pub fn select_limit_offset_execution_result_test() {
  let pgo = select_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_query() |> maria_test_helper.setup_and_run
  let myq = select_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_limit_offset_execution_result_test")
}

pub fn combined_limit_offset_test() {
  combined_query()
  |> to_string
  |> birdie.snap("combined_limit_offset_test")
}

pub fn combined_limit_offset_prepared_statement_test() {
  let pgo = combined_query() |> postgres.read_query_to_prepared_statement
  let lit = combined_query() |> sqlite.read_query_to_prepared_statement
  let mdb = combined_query() |> maria.read_query_to_prepared_statement
  let myq = combined_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_limit_offset_prepared_statement_test")
}

pub fn combined_limit_offset_execution_result_test() {
  let pgo = combined_query() |> postgres_test_helper.setup_and_run
  let lit = combined_query() |> sqlite_test_helper.setup_and_run
  let mdb = combined_query() |> maria_test_helper.setup_and_run
  let myq = combined_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_limit_offset_execution_result_test")
}
