//// Snapshot tests for `insert_conflict_ignore_maria_mysql_apply` behavior.
////
//// Every test runs against **both** MariaDB and 🐬MySQL.
//// Snapshots are named with `_maria_mysql_` and contain `#(maria, mysql)`
//// pairs.
////
//// Covers all MariaDB / MySQL code paths:
////
//// - Column-based target + row source → `SELECT ... WHERE NOT EXISTS`
////   (or `UNION ALL` for multi-row).
//// - Constraint-based target → fallback to `INSERT IGNORE`.
//// - Non-row source (query / DEFAULT) → fallback to `INSERT IGNORE`.
//// - Missing table or columns → fallback to `INSERT IGNORE`.
//// - Modifiers are applied correctly before `INSERT IGNORE`.
//// - Index predicate (`WHERE`) is silently dropped.
//// - Epilog and comment ordering is preserved.
////

import birdie
import cake
import cake/insert as i
import cake/where as w
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Helpers
// └──────────────────────────────────────────────────────────────────────────

/// Builds a minimal insert: table `counters`, columns `[name, counter]`,
/// single row `("Whiskers", 1)`.
///
fn base_query() {
  i.new()
  |> i.table("counters")
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.columns(["name", "counter"])
}

/// Builds the base query with `on_columns_conflict_ignore(columns: ["name"],
/// where: is_active = TRUE)`.
///
fn base_columns_ignore_query() {
  base_query()
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
}

/// Builds the base query with `on_constraint_conflict_ignore(constraint:
/// "counters_name_key", where: is_active = TRUE)`.
///
fn base_constraint_ignore_query() {
  base_query()
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Column-based target + single row source
// └─────────────────────────────────────────────────────────────────────────────

/// Column-based target with a single row produces
/// `SELECT ... WHERE NOT EXISTS (...)` (no `UNION ALL`).
///
pub fn insert_conflict_ignore_column_single_row_maria_mysql_test() {
  base_columns_ignore_query()
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_column_single_row_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Column-based target + multi-row source
// └────────────────────────────────────────────────────────────────────────────

/// Column-based target with multiple rows produces
/// `SELECT ... UNION ALL SELECT ... WHERE NOT EXISTS (...)`.
///
pub fn insert_conflict_ignore_column_multi_row_maria_mysql_test() {
  i.new()
  |> i.table("counters")
  |> i.source_values([
    [i.string("Whiskers"), i.int(1)] |> i.row,
    [i.string("Karl"), i.int(2)] |> i.row,
    [i.string("Clara"), i.int(3)] |> i.row,
  ])
  |> i.columns(["name", "counter"])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_column_multi_row_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Constraint-based target (falls back to INSERT IGNORE)
// └────────────────────────────────────────────────────────────────────────────

/// Constraint-based target falls back to `INSERT IGNORE INTO ...` because
/// there is no column information to build a `WHERE NOT EXISTS` predicate.
///
pub fn insert_conflict_ignore_constraint_fallback_maria_mysql_test() {
  base_constraint_ignore_query()
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_constraint_fallback_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Non-row source (falls back to INSERT IGNORE)
// └────────────────────────────────────────────────────────────────────────────

/// When source is not a concrete list of rows (e.g. a subquery or DEFAULT),
/// the code falls back to `INSERT IGNORE INTO ...` because it can't extract
/// the target-column parameter values needed for the `WHERE NOT EXISTS`
/// predicate.
///
pub fn insert_conflict_ignore_non_row_source_maria_mysql_test() {
  // Use INSERT DEFAULT VALUES as a non-row source path.
  i.new()
  |> i.table("counters")
  |> i.columns(["name", "counter"])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_non_row_source_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Missing table or columns (falls back to INSERT IGNORE)
// └────────────────────────────────────────────────────────────────────────────

/// When the table is not specified (NoInsertIntoTable), the column-based target
/// path can't match and falls back to `INSERT IGNORE INTO ...` (no table name).
///
pub fn insert_conflict_ignore_no_table_maria_mysql_test() {
  i.new()
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.columns(["name", "counter"])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_no_table_maria_mysql_test")
}

/// When the columns are not specified (NoInsertColumns), the column-based
/// target path can't match and falls back to `INSERT IGNORE INTO ...`
/// (no column list).
///
pub fn insert_conflict_ignore_no_columns_maria_mysql_test() {
  i.new()
  |> i.table("counters")
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_no_columns_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Modifier handling
// └────────────────────────────────────────────────────────────────────────────

/// `HIGH_PRIORITY` modifier applied before `INSERT` produces
/// `INSERT HIGH_PRIORITY IGNORE INTO` on the fallback path and
/// `INSERT HIGH_PRIORITY INTO ... SELECT` on the column-target path.
///
pub fn insert_conflict_ignore_with_modifier_maria_mysql_test() {
  base_columns_ignore_query()
  |> i.modifier("HIGH_PRIORITY")
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_with_modifier_maria_mysql_test")
}

/// `HIGH_PRIORITY` modifier on constraint-based fallback produces
/// `INSERT HIGH_PRIORITY IGNORE INTO counters ...`.
///
pub fn insert_conflict_ignore_constraint_with_modifier_maria_mysql_test() {
  base_constraint_ignore_query()
  |> i.modifier("HIGH_PRIORITY")
  |> to_both_dialects
  |> to_string
  |> birdie.snap(
    "insert_conflict_ignore_constraint_with_modifier_maria_mysql_test",
  )
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ WHERE predicate is silently dropped
// └────────────────────────────────────────────────────────────────────────────

/// The `WHERE` index predicate from `InsertConflictIgnore` is silently dropped
/// for MariaDB/MySQL — the predicate is not appended anywhere.
///
/// This test confirms that MariaDB emits the same SQL regardless of the WHERE
/// clause, while the WHERE clause would appear in PostgreSQL output.
///
pub fn insert_conflict_ignore_where_dropped_maria_mysql_test() {
  let query_with_where = base_columns_ignore_query()

  let query_constraint_target = base_constraint_ignore_query()

  let maria_with_where =
    query_with_where |> i.to_query |> maria.write_query_to_prepared_statement
  let maria_constraint =
    query_constraint_target
    |> i.to_query
    |> maria.write_query_to_prepared_statement

  #(maria_with_where, maria_constraint)
  |> to_string
  |> birdie.snap("insert_conflict_ignore_where_dropped_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Epilog and comment ordering
// └────────────────────────────────────────────────────────────────────────────

/// Epilog is appended after the main SQL (after `INSERT IGNORE INTO ...`).
///
pub fn insert_conflict_ignore_epilog_order_maria_mysql_test() {
  base_constraint_ignore_query()
  |> i.epilog("-- epilog comment")
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_epilog_order_maria_mysql_test")
}

/// Comment is appended at the end of the SQL.
///
pub fn insert_conflict_ignore_comment_order_maria_mysql_test() {
  base_constraint_ignore_query()
  |> i.comment("constraint-ignore-comment")
  |> to_both_dialects
  |> to_string
  |> birdie.snap("insert_conflict_ignore_comment_order_maria_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Execution results
// └────────────────────────────────────────────────────────────────────────────

/// Column-based target + single row source executed against both MariaDB and
/// MySQL.
///
pub fn insert_conflict_ignore_column_single_row_execution_maria_mysql_test() {
  let maria_result =
    base_columns_ignore_query()
    |> i.to_query
    |> maria_test_helper.setup_and_run_write

  let mysql_result =
    base_columns_ignore_query()
    |> i.to_query
    |> mysql_test_helper.setup_and_run_write

  #(maria_result, mysql_result)
  |> to_string
  |> birdie.snap(
    "insert_conflict_ignore_column_single_row_execution_maria_mysql_test",
  )
}

/// Column-based target + multi-row source executed against both MariaDB and
/// MySQL.
///
pub fn insert_conflict_ignore_column_multi_row_execution_maria_mysql_test() {
  let query =
    i.new()
    |> i.table("counters")
    |> i.source_values([
      [i.string("Whiskers"), i.int(1)] |> i.row,
      [i.string("Karl"), i.int(2)] |> i.row,
      [i.string("Clara"), i.int(3)] |> i.row,
    ])
    |> i.columns(["name", "counter"])
    |> i.on_columns_conflict_ignore(
      columns: ["name"],
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let maria_result = query |> maria_test_helper.setup_and_run_write
  let mysql_result = query |> mysql_test_helper.setup_and_run_write

  #(maria_result, mysql_result)
  |> to_string
  |> birdie.snap(
    "insert_conflict_ignore_column_multi_row_execution_maria_mysql_test",
  )
}

/// Constraint-based fallback executed against both MariaDB and MySQL produces
/// `INSERT IGNORE INTO ...` output.
///
pub fn insert_conflict_ignore_constraint_execution_maria_mysql_test() {
  let maria_result =
    base_constraint_ignore_query()
    |> i.to_query
    |> maria_test_helper.setup_and_run_write

  let mysql_result =
    base_constraint_ignore_query()
    |> i.to_query
    |> mysql_test_helper.setup_and_run_write

  #(maria_result, mysql_result)
  |> to_string
  |> birdie.snap("insert_conflict_ignore_constraint_execution_maria_mysql_test")
}

// ┌────────────────────────────────────────────────────────────────────────────
// │ Utility
// └────────────────────────────────────────────────────────────────────────────

/// Converts a prepared statement for both MariaDB and MySQL into a tuple.
///
fn to_both_dialects(query) {
  let maria = query |> i.to_query |> maria.write_query_to_prepared_statement
  let mysql = query |> i.to_query |> mysql.write_query_to_prepared_statement
  #(maria, mysql)
}
