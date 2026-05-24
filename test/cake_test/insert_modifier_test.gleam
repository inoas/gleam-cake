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
pub fn insert_or_replace_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("OR REPLACE")
    |> i.to_query

  let sqlite = query |> sqlite.write_query_to_prepared_statement

  to_string(sqlite)
  |> birdie.snap("insert_or_replace_prepared_statement_test")
}

/// Proves `INSERT OR IGNORE INTO cats (name) VALUES ($1)` is generated.
///
pub fn insert_or_ignore_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("OR IGNORE")
    |> i.to_query

  let sqlite = query |> sqlite.write_query_to_prepared_statement

  to_string(sqlite)
  |> birdie.snap("insert_or_ignore_prepared_statement_test")
}

/// Executes `INSERT OR REPLACE INTO` against SQLite to confirm it works.
///
pub fn insert_or_replace_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("OR REPLACE")
    |> i.to_query

  let result = query |> sqlite_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_or_replace_execution_result_test")
}

/// Executes `INSERT OR IGNORE INTO` against SQLite to confirm it works.
///
pub fn insert_or_ignore_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("OR IGNORE")
    |> i.to_query

  let result = query |> sqlite_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_or_ignore_execution_result_test")
}

// ┌──────────────────────────────────────────────────────────────
// │ MySQL / MariaDB modifiers: HIGH_PRIORITY / DELAYED
// └─────────────────────────────────────────────────────────────────

/// Proves `INSERT HIGH_PRIORITY INTO cats (name) VALUES (?)` is generated
/// for both MariaDB and MySQL adapters.
///
pub fn insert_high_priority_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("HIGH_PRIORITY")
    |> i.to_query

  let maria = query |> maria.write_query_to_prepared_statement
  let mysql = query |> mysql.write_query_to_prepared_statement

  #(maria, mysql)
  |> to_string
  |> birdie.snap("insert_high_priority_prepared_statement_test")
}

/// Proves `INSERT DELAYED INTO cats (name) VALUES (?)` is generated
/// for both MariaDB and MySQL adapters.
///
pub fn insert_delayed_prepared_statement_test() {
  let query =
    base_insert()
    |> i.modifier("DELAYED")
    |> i.to_query

  let maria = query |> maria.write_query_to_prepared_statement
  let mysql = query |> mysql.write_query_to_prepared_statement

  #(maria, mysql)
  |> to_string
  |> birdie.snap("insert_delayed_prepared_statement_test")
}

/// Executes `INSERT HIGH_PRIORITY INTO` against both MariaDB and MySQL
/// to confirm it works. The result shape is `#(maria_result, mysql_result)`.
///
pub fn insert_high_priority_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("HIGH_PRIORITY")
    |> i.to_query

  let maria_result = query |> maria_test_helper.setup_and_run_write
  let mysql_result = query |> mysql_test_helper.setup_and_run_write

  #(maria_result, mysql_result)
  |> to_string
  |> birdie.snap("insert_high_priority_execution_result_test")
}

/// Executes `INSERT DELAYED INTO` against MariaDB to confirm it works.
///
pub fn insert_delayed_maria_execution_result_test() {
  let query =
    base_insert()
    |> i.modifier("DELAYED")
    |> i.to_query

  let result = query |> maria_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_delayed_maria_execution_result_test")
}
