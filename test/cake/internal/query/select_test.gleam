import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as sut
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

const const_field = "age"

// TODO v1: test All vs Distinct

fn selects_query() {
  sut.new_from(f.table("cats"))
  |> sut.selects([
    sut.col("name"),
    // sut.bool(True),
    // sut.float(1.0),
    // sut.int(1),
    sut.string("hello"),
    sut.fragment(frgmt.literal(const_field)),
    sut.alias(sut.col("age"), "years_since_birth"),
  ])
  |> sut.to_query
}

pub fn selects_test() {
  selects_query()
  |> to_string
  |> birdie.snap("selects_test")
}

pub fn selects_prepared_statement_test() {
  let pgo = selects_query() |> postgres_adapter.to_prepared_statement
  let lit = selects_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("selects_prepared_statement_test")
}

pub fn selects_execution_result_test() {
  let pgo = selects_query() |> postgres_test_helper.setup_and_run
  let lit = selects_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("selects_execution_result_test")
}

fn selects_distinct_query() {
  sut.new_from(f.table("cats"))
  |> sut.distinct
  |> sut.selects([sut.col("is_wild")])
  |> sut.order_asc("is_wild")
  |> sut.to_query
}

pub fn selects_distinct_test() {
  selects_distinct_query()
  |> to_string
  |> birdie.snap("selects_distinct_test")
}

pub fn selects_distinct_prepared_statement_test() {
  let pgo = selects_distinct_query() |> postgres_adapter.to_prepared_statement
  let lit = selects_distinct_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("selects_distinct_prepared_statement_test")
}

pub fn selects_distinct_execution_result_test() {
  let pgo = selects_distinct_query() |> postgres_test_helper.setup_and_run
  let lit = selects_distinct_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("selects_distinct_execution_result_test")
}
