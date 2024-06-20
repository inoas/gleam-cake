import birdie
import cake/query/update as u
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

fn update() {
  u.new(table: "cats", sets: [
    "age" |> u.col_to_expression("age + 1"),
    "name" |> u.col_to_expression("CONCAT(name, ' the elder')"),
  ])
  |> u.returning(["name", "age"])
}

fn update_query() {
  update()
  |> u.to_query
}

fn update_maria_query() {
  update()
  // MariaDB/MySQL do not support RETURNING in UPDATE queries
  |> u.no_returning
  |> u.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn update_test() {
  let pgo = update_query()
  let lit = pgo
  let mdb = update_maria_query()

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("update_test")
}

pub fn update_prepared_statement_test() {
  let pgo = update_query() |> postgres.write_query_to_prepared_statement
  let lit = update_query() |> sqlite.write_query_to_prepared_statement
  let mdb = update_maria_query() |> maria.write_query_to_prepared_statement

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("update_prepared_statement_test")
}

pub fn update_execution_result_test() {
  let pgo = update_query() |> postgres_test_helper.setup_and_run_write
  let lit = update_query() |> sqlite_test_helper.setup_and_run_write
  let mdb = update_maria_query() |> maria_test_helper.setup_and_run_write

  #(pgo, lit, mdb)
  |> to_string
  |> birdie.snap("update_execution_result_test")
}
