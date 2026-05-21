import birdie
import cake/insert as i
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn insert_with_modifier_query() {
  [[i.string("Nubi")] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name"])
  |> i.modifier("OR REPLACE")
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Bug 9: the modifier is applied after the column list instead of between
/// `INSERT` and `INTO`, producing invalid SQL.
///
/// Correct: INSERT OR REPLACE INTO cats (name) VALUES ($1)
/// Bug:     INSERT INTO cats (name) OR REPLACE VALUES ($1)
///
pub fn insert_modifier_prepared_statement_test() {
  let pgo =
    insert_with_modifier_query() |> postgres.write_query_to_prepared_statement
  let lit =
    insert_with_modifier_query() |> sqlite.write_query_to_prepared_statement
  let mdb =
    insert_with_modifier_query() |> maria.write_query_to_prepared_statement
  let myq =
    insert_with_modifier_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_modifier_prepared_statement_test")
}

/// Executes the insert against all four databases and snapshots the results.
///
/// With the bug the generated SQL is `INSERT INTO cats (name) OR REPLACE VALUES (…)`
/// which is rejected as a syntax error by every engine.
/// Once bug 9 is fixed the SQL becomes `INSERT OR REPLACE INTO cats (name) VALUES (…)`;
/// 🪶SQLite will then execute successfully, while 🐘PostgreSQL, 🦭MariaDB and
/// 🐬MySQL are expected to return an error because `INSERT OR REPLACE` is
/// SQLite-specific syntax.
///
pub fn insert_modifier_execution_result_test() {
  let pgo =
    insert_with_modifier_query() |> postgres_test_helper.setup_and_run_write
  let lit =
    insert_with_modifier_query() |> sqlite_test_helper.setup_and_run_write
  let mdb =
    insert_with_modifier_query() |> maria_test_helper.setup_and_run_write
  let myq =
    insert_with_modifier_query() |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_modifier_execution_result_test")
}
