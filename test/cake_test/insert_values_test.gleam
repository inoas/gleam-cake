import birdie
import cake/query/insert as i
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn insert_values_query() {
  let cat =
    [
      i.param(column: "name", param: "Whiskers" |> i.string),
      i.param(column: "age", param: 5 |> i.int),
      i.param(column: "is_wild", param: False |> i.bool),
    ]
    |> i.row

  i.from_values(
    table_name: "cats",
    columns: ["name", "age", "is_wild"],
    records: [cat],
  )
  |> i.returning(["name"])
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_values_test() {
  insert_values_query()
  |> to_string
  |> birdie.snap("insert_values_test")
}

pub fn insert_values_prepared_statement_test() {
  let pgo = insert_values_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_values_query() |> sqlite.write_query_to_prepared_statement
  let mdb = insert_values_query() |> maria.write_query_to_prepared_statement

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("insert_values_prepared_statement_test")
}

pub fn insert_values_execution_result_test() {
  let pgo = insert_values_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_values_query() |> sqlite_test_helper.setup_and_run_write
  let mdb = insert_values_query() |> maria_test_helper.setup_and_run_write

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("insert_values_execution_result_test")
}
