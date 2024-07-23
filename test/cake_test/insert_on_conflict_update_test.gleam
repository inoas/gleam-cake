import birdie
import cake/insert as i
import cake/update as u
import cake/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/postgres
import test_support/adapter/sqlite

// Notice: Only supports PostgresSQL and SQLite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn update_query() {
  u.new()
  |> u.sets(["counter" |> u.set_expression("counters.counter + 1")])
}

fn insert_on_conflict_update_values() {
  let counters = [
    i.row([i.string("Whiskers"), i.int(1)]),
    i.row([i.string("Karl"), i.int(1)]),
    i.row([i.string("Clara"), i.int(1)]),
  ]

  i.from_values(
    table_name: "counters",
    columns: ["name", "counter"],
    values: counters,
  )
  |> i.on_columns_conflict_update(
    column: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
    update: update_query(),
  )
  |> i.returning(["name", "counter"])
}

fn insert_on_conflict_update_values_query() {
  insert_on_conflict_update_values()
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_on_conflict_update_values_test() {
  let pgo = insert_on_conflict_update_values_query()
  let lit = pgo

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_test")
}

pub fn insert_on_conflict_update_values_prepared_statement_test() {
  let pgo =
    insert_on_conflict_update_values_query()
    |> postgres.write_query_to_prepared_statement
  let lit =
    insert_on_conflict_update_values_query()
    |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_prepared_statement_test")
}

pub fn insert_on_conflict_update_values_execution_result_test() {
  let pgo =
    insert_on_conflict_update_values_query()
    |> postgres_test_helper.setup_and_run_write
  let lit =
    insert_on_conflict_update_values_query()
    |> sqlite_test_helper.setup_and_run_write

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_execution_result_test")
}
