import birdie
import cake/query/combined as c
import cake/query/select as s
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/postgres
import test_support/adapter/sqlite

fn limit_offset_query() {
  s.new()
  |> s.from_table("cats")
  |> s.order_asc("name")
  |> s.limit(4)
  |> s.offset(0)
}

fn select_query() {
  limit_offset_query()
  |> s.to_query
}

pub fn select_limit_offset_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_limit_offset_test")
}

pub fn select_limit_offset_prepared_statement_test() {
  let pgo = select_query() |> postgres.to_prepared_statement
  let lit = select_query() |> sqlite.to_prepared_statement
  let mdb = select_query() |> maria.to_prepared_statement

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("select_limit_offset_prepared_statement_test")
}

pub fn select_limit_offset_execution_result_test() {
  let pgo = select_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_query() |> maria_test_helper.setup_and_run

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("select_limit_offset_execution_result_test")
}

fn combined_query() {
  let limit_offset_query = limit_offset_query()
  limit_offset_query
  |> c.union_all(limit_offset_query)
  |> c.order_asc("name")
  |> c.limit(1)
  |> c.offset(2)
  |> c.to_query
}

pub fn combined_limit_offset_test() {
  combined_query()
  |> to_string
  |> birdie.snap("combined_limit_offset_test")
}

pub fn combined_limit_offset_prepared_statement_test() {
  let pgo = combined_query() |> postgres.to_prepared_statement
  let lit = combined_query() |> sqlite.to_prepared_statement
  let mdb = combined_query() |> maria.to_prepared_statement

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("combined_limit_offset_prepared_statement_test")
}

pub fn combined_limit_offset_execution_result_test() {
  let pgo = combined_query() |> postgres_test_helper.setup_and_run
  let lit = combined_query() |> sqlite_test_helper.setup_and_run
  let mdb = combined_query() |> maria_test_helper.setup_and_run

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("combined_limit_offset_execution_result_test")
}
