import birdie
import cake/insert as i
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/sqlite

// ┌─────────────────────────────────────────────────────────────────────
// │ Setup
// └──────────────────────────────────────────────────────────────────

fn base_insert() {
  [[i.string("Nubi")] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name"])
}

// ┌──────────────────────────────────────────────────────────────
// │ SQLite modifiers: OR REPLACE / OR IGNORE
// └─────────────────────────────────────────────────────────────────

/// Proves `INSERT OR REPLACE INTO cats (name) VALUES ($1)` is generated.
///
pub fn insert_or_replace_sqlite_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("OR REPLACE")
    |> i.to_query

  let lit = query |> sqlite.write_query_to_prepared_statement

  to_string(lit)
  |> birdie.snap("insert_or_replace_sqlite_prepared_statement_test")
}

/// Proves `INSERT OR IGNORE INTO cats (name) VALUES ($1)` is generated.
///
pub fn insert_or_ignore_sqlite_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("OR IGNORE")
    |> i.to_query

  let lit = query |> sqlite.write_query_to_prepared_statement

  to_string(lit)
  |> birdie.snap("insert_or_ignore_sqlite_prepared_statement_test")
}

/// Executes `INSERT OR REPLACE INTO` against SQLite to confirm it works.
///
pub fn insert_or_replace_sqlite_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("OR REPLACE")
    |> i.to_query

  let lit = query |> sqlite_test_helper.setup_and_run_write

  to_string(lit)
  |> birdie.snap("insert_or_replace_sqlite_execution_result_test")
}

/// Executes `INSERT OR IGNORE INTO` against SQLite to confirm it works.
///
pub fn insert_or_ignore_sqlite_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("OR IGNORE")
    |> i.to_query

  let lit = query |> sqlite_test_helper.setup_and_run_write

  to_string(lit)
  |> birdie.snap("insert_or_ignore_sqlite_execution_result_test")
}

// ┌──────────────────────────────────────────────────────────────
// │ MySQL / MariaDB modifiers: HIGH_PRIORITY / DELAYED
// └─────────────────────────────────────────────────────────────────

/// Proves `INSERT HIGH_PRIORITY INTO cats (name) VALUES (?)` is generated
/// for both MariaDB and MySQL adapters.
///
pub fn insert_high_priority_maria_mysql_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("HIGH_PRIORITY")
    |> i.to_query

  let mdb = query |> maria.write_query_to_prepared_statement
  let myq = query |> mysql.write_query_to_prepared_statement

  #(mdb, myq)
  |> to_string
  |> birdie.snap("insert_high_priority_maria_mysql_prepared_statement_test")
}

/// Executes `INSERT HIGH_PRIORITY INTO` against both MariaDB and MySQL
/// to confirm it works. The result shape is `#(mdb_result, myq_result)`.
///
pub fn insert_high_priority_maria_mysql_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("HIGH_PRIORITY")
    |> i.to_query

  let mdb = query |> maria_test_helper.setup_and_run_write
  let myq = query |> mysql_test_helper.setup_and_run_write

  #(mdb, myq)
  |> to_string
  |> birdie.snap("insert_high_priority_maria_mysql_execution_result_test")
}
