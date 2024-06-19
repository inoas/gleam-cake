import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/combined as c
import cake/query/from as f
import cake/query/select as sut
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

fn limit_offset_query() {
  sut.from(f.table("cats"))
  |> sut.order_asc("name")
  |> sut.limit(4)
  |> sut.offset(0)
}

fn select_query() {
  limit_offset_query()
  |> sut.to_query
}

pub fn select_limit_offset_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_limit_offset_test")
}

pub fn select_limit_offset_prepared_statement_test() {
  let pgo = select_query() |> postgres_adapter.to_prepared_statement
  let lit = select_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_limit_offset_prepared_statement_test")
}

pub fn select_limit_offset_execution_result_test() {
  let pgo = select_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_limit_offset_execution_result_test")
}

fn combined_query() {
  let limit_offset_query = limit_offset_query()
  [limit_offset_query, limit_offset_query, limit_offset_query]
  |> c.union_all
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
  let pgo = combined_query() |> postgres_adapter.to_prepared_statement
  let lit = combined_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("combined_limit_offset_prepared_statement_test")
}

pub fn combined_limit_offset_execution_result_test() {
  let pgo = combined_query() |> postgres_test_helper.setup_and_run
  let lit = combined_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("combined_limit_offset_execution_result_test")
}
