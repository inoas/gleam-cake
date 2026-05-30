import birdie
import cake/insert as i
import cake/update as u
import cake/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_support/adapter/postgres

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Background                                                                │
// └───────────────────────────────────────────────────────────────────────────┘
//
// This test verifies `ON CONFLICT ON CONSTRAINT` functionality, which allows
// specifying conflict resolution by named constraint rather than column list.
//
// NOTICE: 🪶SQLite, 🦭MariaDB, and 🐬MySQL do not support this feature.

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn increment_login_count_update() {
  u.new()
  |> u.sets([
    "login_count" |> u.set_expression("users.login_count + 1"),
    "name" |> u.set_expression("EXCLUDED.name"),
  ])
}

/// `INSERT` with `ON CONFLICT ON CONSTRAINT` and `WHERE` clause, generated SQL:
///
/// ```sql
/// INSERT INTO users (email, name, login_count) VALUES ($1, $2, $3)
/// ON CONFLICT ON CONSTRAINT users_email_key
/// WHERE users.login_count < $4
/// DO UPDATE SET login_count = users.login_count + 1, name = EXCLUDED.name
/// RETURNING email, name, login_count
/// ```
fn insert_on_constraint_conflict_update_with_where_query() {
  [
    [i.string("bob@example.com"), i.string("Bob Jones"), i.int(1)]
    |> i.row,
  ]
  |> i.from_values(table_name: "users", columns: [
    "email",
    "name",
    "login_count",
  ])
  |> i.on_constraint_conflict_update(
    constraint: "users_email_key",
    where: w.col("users.login_count") |> w.lt(w.int(100)),
    update: increment_login_count_update(),
  )
  |> i.returning(["email", "name", "login_count"])
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_on_constraint_conflict_update_with_where_test() {
  insert_on_constraint_conflict_update_with_where_query()
  |> to_string
  |> birdie.snap("insert_on_constraint_conflict_update_with_where_test")
}

pub fn insert_on_constraint_conflict_update_with_where_prepared_statement_test() {
  let pgo =
    insert_on_constraint_conflict_update_with_where_query()
    |> postgres.write_query_to_prepared_statement

  pgo
  |> to_string
  |> birdie.snap(
    "insert_on_constraint_conflict_update_with_where_prepared_statement_test",
  )
}

/// NOTICE: Requires PostgreSQL with `users` table and `users_email_key`
/// constraint (created by test helper).
pub fn insert_on_constraint_conflict_update_with_where_execution_result_test() {
  let pgo =
    insert_on_constraint_conflict_update_with_where_query()
    |> postgres_test_helper.setup_and_run_write

  pgo
  |> to_string
  |> birdie.snap(
    "insert_on_constraint_conflict_update_with_where_execution_result_test",
  )
}
