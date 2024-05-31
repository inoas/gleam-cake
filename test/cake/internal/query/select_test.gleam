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

fn selects_query() {
  sut.from(f.table("cats"))
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
  let pgo = selects_query()
  let lit = selects_query()

  #(pgo, lit)
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
