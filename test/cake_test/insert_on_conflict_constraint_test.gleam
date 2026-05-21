import birdie
import cake/insert as i
import cake/update as u
import cake/where as w
import pprint.{format as to_string}
import test_support/adapter/postgres
import test_support/adapter/sqlite

// Notice: Only supports 🐘PostgreSQL and 🪶SQLite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn insert_on_constraint_conflict_ignore_query() {
  [[i.string("Whiskers"), i.int(1)] |> i.row]
  |> i.from_values(table_name: "counters", columns: ["name", "counter"])
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
}

fn update() {
  u.new() |> u.sets(["counter" |> u.set_expression("counters.counter + 1")])
}

fn insert_on_constraint_conflict_update_query() {
  [[i.string("Whiskers"), i.int(1)] |> i.row]
  |> i.from_values(table_name: "counters", columns: ["name", "counter"])
  |> i.on_constraint_conflict_update(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
    update: update(),
  )
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Proves that `insert.on_constraint_conflict_ignore` emits the correct
/// SQL: `ON CONFLICT ON CONSTRAINT name DO NOTHING` rather than
/// wrapping the constraint name in parentheses.
///
pub fn insert_on_constraint_conflict_ignore_prepared_statement_test() {
  let pgo =
    insert_on_constraint_conflict_ignore_query()
    |> postgres.write_query_to_prepared_statement
  let lit =
    insert_on_constraint_conflict_ignore_query()
    |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_constraint_conflict_ignore_prepared_statement_test")
}

/// Proves that `insert.on_constraint_conflict_update` emits the correct
/// SQL: `ON CONFLICT ON CONSTRAINT name DO UPDATE …` rather than
/// wrapping the constraint name in parentheses.
///
pub fn insert_on_constraint_conflict_update_prepared_statement_test() {
  let pgo =
    insert_on_constraint_conflict_update_query()
    |> postgres.write_query_to_prepared_statement
  let lit =
    insert_on_constraint_conflict_update_query()
    |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_on_constraint_conflict_update_prepared_statement_test")
}
