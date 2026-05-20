//// A DSL to build `INSERT` queries.
////

import cake/fragment.{type Fragment}
import cake/internal/read_query.{Comment, Epilog, NoComment, NoEpilog}
import cake/internal/write_query.{
  Insert, InsertColumns, InsertConflictError, InsertConflictIgnore,
  InsertConflictTarget, InsertConflictTargetConstraint, InsertConflictUpdate,
  InsertFragment, InsertIntoTable, InsertModifier, InsertParam, InsertQuery,
  InsertRow, InsertSourceRecords, InsertSourceRows, NoInsertColumns,
  NoInsertIntoTable, NoInsertModifier, NoInsertSource, NoReturning, Returning,
}
import cake/param.{BoolParam, FloatParam, IntParam, NullParam, StringParam}
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Comment =
  read_query.Comment

pub type Epilog =
  read_query.Epilog

pub type Where =
  read_query.Where

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  write_query type re-exports                                              │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Insert(a) =
  write_query.Insert(a)

pub type InsertColumns =
  write_query.InsertColumns

pub type InsertConflictStrategy(a) =
  write_query.InsertConflictStrategy(a)

pub type InsertIntoTable =
  write_query.InsertIntoTable

pub type InsertRow =
  write_query.InsertRow

pub type InsertSource(a) =
  write_query.InsertSource(a)

pub type InsertValue =
  write_query.InsertValue

pub type Update(a) =
  write_query.Update(a)

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Creates a `WriteQuery` from an `Insert` query.
///
pub fn to_query(insert insert: Insert(a)) -> WriteQuery(a) {
  insert |> InsertQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

/// Create an `InsertRow` from a list of `InsertValue`s.
///
pub fn row(values values: List(InsertValue)) -> InsertRow {
  values |> InsertRow
}

/// Create an `InsertValue` from a column `String` and a `Bool` value.
///
pub fn bool(value value: Bool) -> InsertValue {
  value |> BoolParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `Float` value.
///
pub fn float(value value: Float) -> InsertValue {
  value |> FloatParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and an `Int` value.
///
pub fn int(value value: Int) -> InsertValue {
  value |> IntParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `String` value.
///
pub fn string(value value: String) -> InsertValue {
  value |> StringParam |> InsertParam
}

/// Create a NULL `InsertValue`.
///
pub fn null() -> InsertValue {
  NullParam |> InsertParam
}

/// Create an `InsertValue` from a `Fragment`.
///
/// ## Example
///
/// ```gleam
/// import cake/fragment as f
/// import cake/insert as i
///
/// i.fragment(f.prepared("$::uuid", [f.string("0000000000-0000-4000-a000-a00000000000")]))
/// ```
///
pub fn fragment(value fragment: Fragment) -> InsertValue {
  InsertFragment(fragment: fragment)
}

// ▒▒▒ Constructors ▒▒▒

/// Create an empty `INSERT` query.
///
pub fn new() -> Insert(a) {
  Insert(
    table: NoInsertIntoTable,
    modifier: NoInsertModifier,
    source: NoInsertSource,
    columns: NoInsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Create an `INSERT` query from a list of gleam records.
///
/// The `encoder` function is used to convert each record into an `InsertRow`.
///
pub fn from_records(
  table_name table_name: String,
  columns columns: List(String),
  records records: List(a),
  encoder encoder: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(
    table: table_name |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: records |> InsertSourceRecords(encoder: encoder),
    columns: columns |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Create an `INSERT` query from a list of `InsertRow`s.
///
pub fn from_values(
  table_name table_name: String,
  columns columns: List(String),
  values values: List(InsertRow),
) -> Insert(a) {
  Insert(
    table: table_name |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: values |> InsertSourceRows,
    columns: columns |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Specify the table to insert into.
///
pub fn table(
  insert insert: Insert(a),
  table_name table_name: String,
) -> Insert(a) {
  Insert(..insert, table: table_name |> InsertIntoTable)
}

/// Get the table name to insert into from an `Insert` query.
///
pub fn get_table(insert insert: Insert(a)) -> InsertIntoTable {
  insert.table
}

// ▒▒▒ Modifier ▒▒▒

/// Specify a modifier for the `INSERT` query.
///
pub fn modifier(
  insert insert: Insert(a),
  modifier modifier: String,
) -> Insert(a) {
  let modifier = modifier |> string.trim
  case modifier {
    "" -> Insert(..insert, modifier: NoInsertModifier)
    _ -> Insert(..insert, modifier: modifier |> InsertModifier)
  }
}

/// Specify that no modifier should be used for the given `INSERT` query.
///
pub fn no_modifier(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, modifier: NoInsertModifier)
}

/// Get the modifier from an `Insert` query.
///
pub fn get_modifier(insert insert: Insert(a)) -> String {
  case insert.modifier {
    NoInsertModifier -> ""
    InsertModifier(modifier) -> modifier
  }
}

// ▒▒▒ Source ▒▒▒

/// Specify the source records to insert.
///
pub fn source_records(
  insert insert: Insert(a),
  source records: List(a),
  encoder encoder: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(..insert, source: records |> InsertSourceRecords(encoder: encoder))
}

/// Specify the source values to insert.
///
pub fn source_values(
  insert insert: Insert(a),
  source rows: List(InsertRow),
) -> Insert(a) {
  Insert(..insert, source: rows |> InsertSourceRows)
}

/// Get the source from an `Insert` query which is either a list of records,
/// accompanied by a encoder function or a list of `InsertRow`s.
///
pub fn get_source(insert insert: Insert(a)) -> InsertSource(a) {
  insert.source
}

/// Specify the columns to insert into.
///
/// NOTICE: You have to specify the columns and keep track if their names are
/// correct, as well as their count which must be equal to the count of
/// `InsertRows` the encoder function returns or is given as source
///          values.
///
pub fn columns(
  insert insert: Insert(a),
  columns columns: List(String),
) -> Insert(a) {
  Insert(..insert, columns: columns |> InsertColumns)
}

/// Get the columns to insert into from an `Insert` query.
///
pub fn get_columns(insert insert: Insert(a)) -> InsertColumns {
  insert.columns
}

// ▒▒▒ ON CONFLICT ▒▒▒

/// This specifies that any conflicts result in the query to fail
///
/// This is the default behaviour.
///
pub fn on_conflict_error(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, on_conflict: InsertConflictError)
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_ignore(
  insert insert: Insert(a),
  columns columns: List(String),
  where where: Where,
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictIgnore(
      target: columns |> InsertConflictTarget,
      where: where,
    ),
  )
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_ignore(
  insert insert: Insert(a),
  constraint constraint: String,
  where where: Where,
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictIgnore(
      target: constraint |> InsertConflictTargetConstraint,
      where: where,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_update(
  insert insert: Insert(a),
  columns columns: List(String),
  where where: Where,
  update update: Update(a),
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictUpdate(
      target: columns |> InsertConflictTarget,
      where: where,
      update: update,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_update(
  insert insert: Insert(a),
  constraint constraint: String,
  where where: Where,
  update update: Update(a),
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictUpdate(
      target: constraint |> InsertConflictTargetConstraint,
      where: where,
      update: update,
    ),
  )
}

/// Get the conflict strategy from an `Insert` query.
///
pub fn get_on_conflict(insert insert: Insert(a)) -> InsertConflictStrategy(a) {
  insert.on_conflict
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `INSERT` query.
///
pub fn returning(
  insert insert: Insert(a),
  returning returning: List(String),
) -> Insert(a) {
  case returning {
    [] -> Insert(..insert, returning: NoReturning)
    _ -> Insert(..insert, returning: returning |> Returning)
  }
}

/// Specify that no columns should be returned after the `INSERT` query.
///
pub fn no_returning(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `INSERT` query.
///
pub fn epilog(insert insert: Insert(a), epilog epilog: String) -> Insert(a) {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Insert(..insert, epilog: NoEpilog)
    _ -> Insert(..insert, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `INSERT` query.
///
pub fn no_epilog(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, epilog: NoEpilog)
}

/// Get the epilog from an `INSERT` query.
///
pub fn get_epilog(insert insert: Insert(a)) -> Epilog {
  insert.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `INSERT` query.
///
pub fn comment(insert insert: Insert(a), comment comment: String) -> Insert(a) {
  let comment = comment |> string.trim
  case comment {
    "" -> Insert(..insert, comment: NoComment)
    _ -> Insert(..insert, comment: { " " <> comment } |> Comment)
  }
}

/// Specify that no comment should be added to the `INSERT` query.
///
pub fn no_comment(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, comment: NoComment)
}

/// Get the comment from an `INSERT` query.
///
pub fn get_comment(insert insert: Insert(a)) -> Comment {
  insert.comment
}
