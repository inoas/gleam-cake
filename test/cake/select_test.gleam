import birdie
import cake/adapter/postgres
import cake/adapter/sqlite
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as sut
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

const const_field = "age"

fn select_query() {
  sut.new_from(f.table("cats"))
  |> sut.select([
    sut.col("name"),
    // TODO v1 check if this should work AT ALL, because it does not work in postgres
    // sut.bool(True),
    // sut.float(1.0),
    // sut.int(1),
    sut.string("hello"),
    sut.fragment(frgmt.literal(const_field)),
    sut.alias(sut.col("age"), "years_since_birth"),
  ])
  |> sut.to_query
}

pub fn select_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_test")
}

pub fn select_prepared_statement_test() {
  let pgo = select_query() |> postgres.to_prepared_statement
  let lit = select_query() |> sqlite.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_prepared_statement_test")
}

pub fn select_execution_result_test() {
  let pgo = select_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_execution_result_test")
}

fn select_distinct_query() {
  sut.new_from(f.table("cats"))
  |> sut.distinct
  |> sut.select([sut.col("is_wild")])
  |> sut.order_asc("is_wild")
  |> sut.to_query
}

pub fn select_distinct_test() {
  select_distinct_query()
  |> to_string
  |> birdie.snap("select_distinct_test")
}

pub fn select_distinct_prepared_statement_test() {
  let pgo = select_distinct_query() |> postgres.to_prepared_statement
  let lit = select_distinct_query() |> sqlite.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_distinct_prepared_statement_test")
}

pub fn select_distinct_execution_result_test() {
  let pgo = select_distinct_query() |> postgres_test_helper.setup_and_run
  let lit = select_distinct_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("select_distinct_execution_result_test")
}
