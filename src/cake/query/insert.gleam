//// A DSL to build `INSERT` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type Where, Comment, Epilog, NoComment, NoEpilog,
}
import cake/internal/write_query.{
  type Insert, type InsertRow, type InsertSource, type InsertValue, type Update,
  type WriteQuery, Insert, InsertColumns, InsertConflictError,
  InsertConflictIgnore, InsertConflictTarget, InsertConflictTargetConstraint,
  InsertConflictUpdate, InsertIntoTable, InsertModifier, InsertParam,
  InsertQuery, InsertRow, InsertSourceRecords, InsertSourceRows,
  NoInsertModifier, NoReturning, Returning,
}
import cake/param.{type Param}
import gleam/string

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

/// Create an `InsertValue` from a column `String` and a `Param`.
pub fn param(column col: String, param prm: Param) -> InsertValue {
  col |> InsertParam(param: prm)
}

/// Create an `InsertValue` from a column `String` and a `Bool` value.
///
pub fn bool(value vl: Bool) -> Param {
  vl |> param.bool
}

/// Create an `InsertValue` from a column `String` and a `Float` value.
///
pub fn float(value vl: Float) -> Param {
  vl |> param.float
}

/// Create an `InsertValue` from a column `String` and an `Int` value.
///
pub fn int(value vl: Int) -> Param {
  vl |> param.int
}

/// Create an `InsertValue` from a column `String` and a `String` value.
///
pub fn string(value vl: String) -> Param {
  vl |> param.string
}

/// Create a NULL `InsertValue`.
///
pub fn null() -> Param {
  param.NullParam
}

// ▒▒▒ Constructors ▒▒▒

/// Create an `INSERT` query from a list of gleam records.
///
/// The `caster` function is used to convert each record into an `InsertRow`.
///
pub fn from_records(
  table_name tbl_nm: String,
  columns cols: List(String),
  records rcrds: List(a),
  caster cstr: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(
    table: InsertIntoTable(name: tbl_nm),
    modifier: NoInsertModifier,
    source: InsertSourceRecords(records: rcrds, caster: cstr),
    columns: InsertColumns(columns: cols),
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
  records rcrds: List(InsertRow),
) -> Insert(a) {
  Insert(
    table: InsertIntoTable(name: tbl_nm),
    modifier: NoInsertModifier,
    source: InsertSourceRows(records: rcrds),
    columns: InsertColumns(columns: cols),
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Specify the table to insert into.
///
pub fn table(query qry: Insert(a), table_name tbl_nm: String) -> Insert(a) {
  Insert(..qry, table: InsertIntoTable(name: tbl_nm))
}

/// Get the table name to insert into from an `Insert` query.
///
pub fn get_table(query qry: Insert(a)) -> String {
  qry.table.name
}

// ▒▒▒ Modifier ▒▒▒

/// Specify a modifier for the `INSERT` query.
///
pub fn modifier(query qry: Insert(a), modifier mdfr: String) -> Insert(a) {
  let mdfr = mdfr |> string.trim
  case mdfr {
    "" -> Insert(..qry, modifier: NoInsertModifier)
    _ -> Insert(..qry, modifier: InsertModifier(mdfr))
  }
}

/// Specify that no modifier should be used for the given `INSERT` query.
///
pub fn no_modifier(query qry: Insert(a)) -> Insert(a) {
  Insert(..qry, modifier: NoInsertModifier)
}

/// Get the modifier from an `Insert` query.
///
pub fn get_modifier(query qry: Insert(a)) -> String {
  case qry.modifier {
    NoInsertModifier -> ""
    InsertModifier(mdfr) -> mdfr
  }
}

// ▒▒▒ Source ▒▒▒

/// Specify the source records to insert.
///
pub fn source_records(
  query qry: Insert(a),
  source rcrds: List(a),
  caster cstr: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(..qry, source: InsertSourceRecords(records: rcrds, caster: cstr))
}

/// Specify the source values to insert.
///
pub fn source_values(
  query qry: Insert(a),
  records rcrds: List(InsertRow),
) -> Insert(a) {
  Insert(..qry, source: InsertSourceRows(records: rcrds))
}

/// Get the source from an `Insert` query which is either a list of records,
/// accompanied by a caster function or a list of `InsertRow`s.
///
pub fn get_source(query qry: Insert(a)) -> InsertSource(a) {
  qry.source
}

/// Specify the columns to insert into.
///
/// NOTICE: You have to specify the columns and keep track if their names are
/// correct, as well as their count which must be equal to the count of
/// `InsertRows` the caster function returns or is given as source
///          values.
///
pub fn columns(query qry: Insert(a), columns cols: List(String)) -> Insert(a) {
  Insert(..qry, columns: InsertColumns(columns: cols))
}

// ▒▒▒ ON CONFLICT ▒▒▒

/// This specifies that any conflicts result in the query to fail
///
/// This is the default behaviour.
///
pub fn on_conflict_error(query qry: Insert(a)) -> Insert(a) {
  Insert(..qry, on_conflict: InsertConflictError)
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_ignore(
  query qry: Insert(a),
  column cols: List(String),
  where whr: Where,
) -> Insert(a) {
  Insert(
    ..qry,
    on_conflict: InsertConflictIgnore(
      target: InsertConflictTarget(columns: cols),
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
  query qry: Insert(a),
  constraint cnstrt: String,
  where whr: Where,
) -> Insert(a) {
  Insert(
    ..qry,
    on_conflict: InsertConflictIgnore(
      target: InsertConflictTargetConstraint(constraint: cnstrt),
      where: whr,
    ),
  )
}

/// Inserts or updates on conflict, also called ´.UPSERT´.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_update(
  query qry: Insert(a),
  column cols: List(String),
  where whr: Where,
  update updt: Update(a),
) -> Insert(a) {
  Insert(
    ..qry,
    on_conflict: InsertConflictUpdate(
      target: InsertConflictTarget(columns: cols),
      where: whr,
      update: updt,
    ),
  )
}

/// Inserts or updates on conflict, also called ´.UPSERT´.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_update(
  query qry: Insert(a),
  constraint cnstrt: String,
  where whr: Where,
  update updt: Update(a),
) -> Insert(a) {
  Insert(
    ..qry,
    on_conflict: InsertConflictUpdate(
      target: InsertConflictTargetConstraint(constraint: cnstrt),
      where: whr,
      update: updt,
    ),
  )
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `INSERT` query.
///
pub fn returning(
  query qry: Insert(a),
  returning rtrn: List(String),
) -> Insert(a) {
  case rtrn {
    [] -> Insert(..qry, returning: NoReturning)
    _ -> Insert(..qry, returning: Returning(rtrn))
  }
}

/// Specify that no columns should be returned after the `INSERT` query.
///
pub fn no_returning(query qry: Insert(a)) -> Insert(a) {
  Insert(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `INSERT` query.
///
pub fn epilog(query qry: Insert(a), epilog eplg: String) -> Insert(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Insert(..qry, epilog: NoEpilog)
    _ -> Insert(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `INSERT` query.
///
pub fn no_epilog(query qry: Insert(a)) -> Insert(a) {
  Insert(..qry, epilog: NoEpilog)
}

/// Get the epilog from an `INSERT` query.
///
pub fn get_epilog(query qry: Insert(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `INSERT` query.
///
pub fn comment(query qry: Insert(a), comment cmmnt: String) -> Insert(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Insert(..qry, comment: NoComment)
    _ -> Insert(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Specify that no comment should be added to the `INSERT` query.
///
pub fn no_comment(query qry: Insert(a)) -> Insert(a) {
  Insert(..qry, comment: NoComment)
}

/// Get the comment from an `INSERT` query.
///
pub fn get_comment(query qry: Insert(a)) -> Comment {
  qry.comment
}
