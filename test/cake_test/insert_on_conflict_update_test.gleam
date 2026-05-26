import birdie
import cake/insert as i
import cake/update as u
import cake/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn upsert_counter_update() {
  u.new()
  |> u.set("counter" |> u.set_expression("excluded.counter"))
}

/// Insert a row that conflicts on `name`; on conflict update `counter`.
///
/// Conflict target: column list — supported by 🐘PostgreSQL and 🪶SQLite.
///
fn insert_on_columns_conflict_update_query() {
  [[i.string("Fubi"), i.int(1), i.bool(True)] |> i.row]
  |> i.from_values(table_name: "counters", columns: [
    "name",
    "counter",
    "is_active",
  ])
  |> i.on_columns_conflict_update(
    columns: ["name"],
    where: w.none(),
    update: upsert_counter_update(),
  )
  |> i.returning(["name", "counter"])
  |> i.to_query
}

/// Insert a row that conflicts on the named constraint `counters_name_unique`;
/// on conflict update `counter`.
///
/// Conflict target: named constraint — 🐘PostgreSQL only.
///
fn insert_pgo_on_constraint_conflict_update_query() {
  [[i.string("Fubi"), i.int(1), i.bool(True)] |> i.row]
  |> i.from_values(table_name: "counters", columns: [
    "name",
    "counter",
    "is_active",
  ])
  |> i.on_constraint_conflict_update(
    constraint: "counters_name_unique",
    where: w.none(),
    update: upsert_counter_update(),
  )
  |> i.returning(["name", "counter"])
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_on_columns_conflict_update_test() {
  let pgo = insert_on_columns_conflict_update_query()
  let lit = pgo

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_columns_conflict_update_test")
}

pub fn insert_pgo_on_constraint_conflict_update_test() {
  insert_pgo_on_constraint_conflict_update_query()
  |> to_string
  |> birdie.snap("insert_pgo_on_constraint_conflict_update_test")
}

pub fn insert_on_columns_conflict_update_prepared_statement_test() {
  let pgo =
    insert_on_columns_conflict_update_query()
    |> postgres.write_query_to_prepared_statement
  let lit =
    insert_on_columns_conflict_update_query()
    |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_columns_conflict_update_prepared_statement_test")
}

pub fn insert_pgo_on_constraint_conflict_update_prepared_statement_test() {
  insert_pgo_on_constraint_conflict_update_query()
  |> postgres.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap(
    "insert_pgo_on_constraint_conflict_update_prepared_statement_test",
  )
}

pub fn insert_on_columns_conflict_update_execution_result_test() {
  let pgo =
    insert_on_columns_conflict_update_query()
    |> postgres_test_helper.setup_and_run_write
  let lit =
    insert_on_columns_conflict_update_query()
    |> sqlite_test_helper.setup_and_run_write

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_columns_conflict_update_execution_result_test")
}

pub fn insert_pgo_on_constraint_conflict_update_execution_result_test() {
  insert_pgo_on_constraint_conflict_update_query()
  |> postgres_test_helper.setup_and_run_write
  |> to_string
  |> birdie.snap(
    "insert_pgo_on_constraint_conflict_update_execution_result_test",
  )
}
