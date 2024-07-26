//// A DSL to build `INSERT` queries.
////

import cake/internal/read_query.{Comment, Epilog, NoComment, NoEpilog}
import cake/internal/write_query.{
  Insert, InsertColumns, InsertConflictError, InsertConflictIgnore,
  InsertConflictTarget, InsertConflictTargetConstraint, InsertConflictUpdate,
  InsertIntoTable, InsertModifier, InsertParam, InsertQuery, InsertRow,
  InsertSourceRecords, InsertSourceRows, NoInsertColumns, NoInsertIntoTable,
  NoInsertModifier, NoInsertSource, NoReturning, Returning,
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
pub fn to_query(insert isrt: Insert(a)) -> WriteQuery(a) {
  isrt |> InsertQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

/// Create an `InsertRow` from a list of `InsertValue`s.
///
pub fn row(values vls: List(InsertValue)) -> InsertRow {
  vls |> InsertRow
}

/// Create an `InsertValue` from a column `String` and a `Bool` value.
///
pub fn bool(value vl: Bool) -> InsertValue {
  vl |> BoolParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `Float` value.
///
pub fn float(value vl: Float) -> InsertValue {
  vl |> FloatParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and an `Int` value.
///
pub fn int(value vl: Int) -> InsertValue {
  vl |> IntParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `String` value.
///
pub fn string(value vl: String) -> InsertValue {
  vl |> StringParam |> InsertParam
}

/// Create a NULL `InsertValue`.
///
pub fn null() -> InsertValue {
  NullParam |> InsertParam
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
  table_name tbl_nm: String,
  columns cols: List(String),
  records rcrds: List(a),
  encoder encdr: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(
    table: tbl_nm |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: rcrds |> InsertSourceRecords(encoder: encdr),
    columns: cols |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Create an `INSERT` query from a list of `InsertRow`s.
///
pub fn from_values(
  table_name tbl_nm: String,
  columns cols: List(String),
  values vls: List(InsertRow),
) -> Insert(a) {
  Insert(
    table: tbl_nm |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: vls |> InsertSourceRows,
    columns: cols |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Specify the table to insert into.
///
pub fn table(insert isrt: Insert(a), table_name tbl_nm: String) -> Insert(a) {
  Insert(..isrt, table: tbl_nm |> InsertIntoTable)
}

/// Get the table name to insert into from an `Insert` query.
///
pub fn get_table(insert isrt: Insert(a)) -> InsertIntoTable {
  isrt.table
}

// ▒▒▒ Modifier ▒▒▒

/// Specify a modifier for the `INSERT` query.
///
pub fn modifier(insert isrt: Insert(a), modifier mdfr: String) -> Insert(a) {
  let mdfr = mdfr |> string.trim
  case mdfr {
    "" -> Insert(..isrt, modifier: NoInsertModifier)
    _ -> Insert(..isrt, modifier: mdfr |> InsertModifier)
  }
}

/// Specify that no modifier should be used for the given `INSERT` query.
///
pub fn no_modifier(insert isrt: Insert(a)) -> Insert(a) {
  Insert(..isrt, modifier: NoInsertModifier)
}

/// Get the modifier from an `Insert` query.
///
pub fn get_modifier(insert isrt: Insert(a)) -> String {
  case isrt.modifier {
    NoInsertModifier -> ""
    InsertModifier(mdfr) -> mdfr
  }
}

// ▒▒▒ Source ▒▒▒

/// Specify the source records to insert.
///
pub fn source_records(
  insert isrt: Insert(a),
  source rcrds: List(a),
  encoder encdr: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(..isrt, source: rcrds |> InsertSourceRecords(encoder: encdr))
}

/// Specify the source values to insert.
///
pub fn source_values(
  insert isrt: Insert(a),
  source rws: List(InsertRow),
) -> Insert(a) {
  Insert(..isrt, source: rws |> InsertSourceRows)
}

/// Get the source from an `Insert` query which is either a list of records,
/// accompanied by a encoder function or a list of `InsertRow`s.
///
pub fn get_source(insert isrt: Insert(a)) -> InsertSource(a) {
  isrt.source
}

/// Specify the columns to insert into.
///
/// NOTICE: You have to specify the columns and keep track if their names are
/// correct, as well as their count which must be equal to the count of
/// `InsertRows` the encoder function returns or is given as source
///          values.
///
pub fn columns(insert isrt: Insert(a), columns cols: List(String)) -> Insert(a) {
  Insert(..isrt, columns: cols |> InsertColumns)
}

/// Get the columns to insert into from an `Insert` query.
///
pub fn get_columns(insert isrt: Insert(a)) -> InsertColumns {
  isrt.columns
}

// ▒▒▒ ON CONFLICT ▒▒▒

/// This specifies that any conflicts result in the query to fail
///
/// This is the default behaviour.
///
pub fn on_conflict_error(insert isrt: Insert(a)) -> Insert(a) {
  Insert(..isrt, on_conflict: InsertConflictError)
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_ignore(
  insert isrt: Insert(a),
  columns cols: List(String),
  where whr: Where,
) -> Insert(a) {
  Insert(
    ..isrt,
    on_conflict: InsertConflictIgnore(
      target: cols |> InsertConflictTarget,
      where: whr,
    ),
  )
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_ignore(
  insert isrt: Insert(a),
  constraint cnstrt: String,
  where whr: Where,
) -> Insert(a) {
  Insert(
    ..isrt,
    on_conflict: InsertConflictIgnore(
      target: cnstrt |> InsertConflictTargetConstraint,
      where: whr,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_update(
  insert isrt: Insert(a),
  columns cols: List(String),
  where whr: Where,
  update updt: Update(a),
) -> Insert(a) {
  Insert(
    ..isrt,
    on_conflict: InsertConflictUpdate(
      target: cols |> InsertConflictTarget,
      where: whr,
      update: updt,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_update(
  insert isrt: Insert(a),
  constraint cnstrt: String,
  where whr: Where,
  update updt: Update(a),
) -> Insert(a) {
  Insert(
    ..isrt,
    on_conflict: InsertConflictUpdate(
      target: cnstrt |> InsertConflictTargetConstraint,
      where: whr,
      update: updt,
    ),
  )
}

/// Get the conflict strategy from an `Insert` query.
///
pub fn get_on_conflict(insert isrt: Insert(a)) -> InsertConflictStrategy(a) {
  isrt.on_conflict
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `INSERT` query.
///
pub fn returning(
  insert isrt: Insert(a),
  returning rtrn: List(String),
) -> Insert(a) {
  case rtrn {
    [] -> Insert(..isrt, returning: NoReturning)
    _ -> Insert(..isrt, returning: rtrn |> Returning)
  }
}

/// Specify that no columns should be returned after the `INSERT` query.
///
pub fn no_returning(insert isrt: Insert(a)) -> Insert(a) {
  Insert(..isrt, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `INSERT` query.
///
pub fn epilog(insert isrt: Insert(a), epilog eplg: String) -> Insert(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Insert(..isrt, epilog: NoEpilog)
    _ -> Insert(..isrt, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `INSERT` query.
///
pub fn no_epilog(insert isrt: Insert(a)) -> Insert(a) {
  Insert(..isrt, epilog: NoEpilog)
}

/// Get the epilog from an `INSERT` query.
///
pub fn get_epilog(insert isrt: Insert(a)) -> Epilog {
  isrt.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `INSERT` query.
///
pub fn comment(insert isrt: Insert(a), comment cmmnt: String) -> Insert(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Insert(..isrt, comment: NoComment)
    _ -> Insert(..isrt, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Specify that no comment should be added to the `INSERT` query.
///
pub fn no_comment(insert isrt: Insert(a)) -> Insert(a) {
  Insert(..isrt, comment: NoComment)
}

/// Get the comment from an `INSERT` query.
///
pub fn get_comment(insert isrt: Insert(a)) -> Comment {
  isrt.comment
}
