//// Snapshot tests for `insert_conflict_ignore_maria_mysql_apply` behavior.
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
import cake/insert as i
import cake/where as w
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql

// Helper to build a minimal insert query with table, columns, and single row.
fn base_ignore_query() {
  i.new()
  |> i.table("counters")
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.columns(["name", "counter"])
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Column-based target + single row source
// └────────────────────────────────────────────────────────────────────────────

/// Column-based target with a single row produces
/// `SELECT ... WHERE NOT EXISTS (...)` (no `UNION ALL`).
///
pub fn insert_conflict_ignore_column_single_row_test() {
  base_ignore_query()
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_column_single_row_test")
}

/// Same as above, for MySQL.
///
pub fn insert_conflict_ignore_column_single_row_mysql_test() {
  base_ignore_query()
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> mysql.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_column_single_row_mysql_test")
}

/// Column-based target with multiple rows produces
/// `SELECT ... UNION ALL SELECT ... WHERE NOT EXISTS (...)`.
///
pub fn insert_conflict_ignore_column_multi_row_test() {
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
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_column_multi_row_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Constraint-based target (falls back to INSERT IGNORE)
// └───────────────────────────────────────────────────────────────────────────

/// Constraint-based target falls back to `INSERT IGNORE INTO ...` because
/// there is no column information to build a `WHERE NOT EXISTS` predicate.
///
pub fn insert_conflict_ignore_constraint_fallback_test() {
  base_ignore_query()
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_constraint_fallback_test")
}

/// Same fallback for MySQL.
///
pub fn insert_conflict_ignore_constraint_fallback_mysql_test() {
  base_ignore_query()
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> mysql.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_constraint_fallback_mysql_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Missing table or columns (falls back to INSERT IGNORE)
// └───────────────────────────────────────────────────────────────────────────

/// When the table is not specified (NoInsertIntoTable), falls back to
/// `INSERT IGNORE INTO ...` (no table name).
///
pub fn insert_conflict_ignore_no_table_fallback_test() {
  i.new()
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.columns(["name", "counter"])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_no_table_fallback_test")
}

/// When the columns are not specified (NoInsertColumns), falls back to
/// `INSERT IGNORE INTO ...` (no column list).
///
pub fn insert_conflict_ignore_no_columns_fallback_test() {
  i.new()
  |> i.table("counters")
  |> i.source_values([[i.string("Whiskers"), i.int(1)] |> i.row])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_no_columns_fallback_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Modifier handling (applied before INSERT and before INSERT IGNORE)
// └───────────────────────────────────────────────────────────────────────────

/// `HIGH_PRIORITY` modifier is applied to `INSERT HIGH_PRIORITY IGNORE INTO`.
///
pub fn insert_conflict_ignore_with_modifier_test() {
  base_ignore_query()
  |> i.modifier("HIGH_PRIORITY")
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_with_modifier_test")
}

/// `HIGH_PRIORITY` modifier on constraint-based fallback produces
/// `INSERT HIGH_PRIORITY IGNORE INTO counters ...`.
///
pub fn insert_conflict_ignore_constraint_with_modifier_test() {
  base_ignore_query()
  |> i.modifier("HIGH_PRIORITY")
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_constraint_with_modifier_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ WHERE predicate is silently dropped
// └───────────────────────────────────────────────────────────────────────────

/// The `WHERE` index predicate from `InsertConflictIgnore` is silently dropped
/// for MariaDB/MySQL — the predicate is not appended anywhere.
///
/// This test compares a column-based target (which would emit `SELECT ...
/// WHERE NOT EXISTS`) against a constraint-based target (which falls back
/// to `INSERT IGNORE`). Both silently drop the WHERE clause.
///
pub fn insert_conflict_ignore_where_dropped_comparison_test() {
  let query_with_where =
    base_ignore_query()
    |> i.on_columns_conflict_ignore(
      columns: ["name"],
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let query_constraint_target =
    base_ignore_query()
    |> i.on_constraint_conflict_ignore(
      constraint: "counters_name_key",
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let maria_with_where =
    query_with_where |> maria.write_query_to_prepared_statement
  let maria_constraint =
    query_constraint_target |> maria.write_query_to_prepared_statement

  #(maria_with_where, maria_constraint)
  |> to_string
  |> birdie.snap("insert_conflict_ignore_where_dropped_comparison_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Epilog and comment ordering
// └───────────────────────────────────────────────────────────────────────────

/// Epilog is appended after the main SQL (after `INSERT IGNORE INTO ...`).
///
pub fn insert_conflict_ignore_epilog_order_test() {
  base_ignore_query()
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.epilog("-- epilog comment")
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_epilog_order_test")
}

/// Comment is appended at the end of the SQL.
///
pub fn insert_conflict_ignore_comment_order_test() {
  base_ignore_query()
  |> i.on_constraint_conflict_ignore(
    constraint: "counters_name_key",
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.comment("constraint-ignore-comment")
  |> i.to_query
  |> maria.write_query_to_prepared_statement
  |> to_string
  |> birdie.snap("insert_conflict_ignore_comment_order_test")
}

// ┌─────────────────────────────────────────────────────────────────────────────
// │ Execution results
// └───────────────────────────────────────────────────────────────────────────

/// Column-based target + single row source executed against MariaDB.
///
pub fn insert_conflict_ignore_column_single_row_execution_test() {
  let query =
    base_ignore_query()
    |> i.on_columns_conflict_ignore(
      columns: ["name"],
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let result = query |> maria_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_conflict_ignore_column_single_row_execution_test")
}

/// Column-based target + single row source executed against MySQL.
///
pub fn insert_conflict_ignore_column_single_row_execution_mysql_test() {
  let query =
    base_ignore_query()
    |> i.on_columns_conflict_ignore(
      columns: ["name"],
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let result = query |> mysql_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap(
    "insert_conflict_ignore_column_single_row_execution_mysql_test",
  )
}

/// Constraint-based fallback executed against MariaDB produces
/// `INSERT IGNORE INTO ...` output.
///
pub fn insert_conflict_ignore_constraint_execution_test() {
  let query =
    base_ignore_query()
    |> i.on_constraint_conflict_ignore(
      constraint: "counters_name_key",
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let result = query |> maria_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_conflict_ignore_constraint_execution_test")
}

/// Constraint-based fallback executed against MySQL produces
/// `INSERT IGNORE INTO ...` output.
///
pub fn insert_conflict_ignore_constraint_execution_mysql_test() {
  let query =
    base_ignore_query()
    |> i.on_constraint_conflict_ignore(
      constraint: "counters_name_key",
      where: w.col("counters.is_active") |> w.is_true,
    )
    |> i.to_query

  let result = query |> mysql_test_helper.setup_and_run_write

  to_string(result)
  |> birdie.snap("insert_conflict_ignore_constraint_execution_mysql_test")
}
