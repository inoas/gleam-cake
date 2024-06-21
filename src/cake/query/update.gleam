//// A DSL to build `UPDATE` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type Joins, type Query, type Where, AndWhere,
  Comment, Epilog, FromSubQuery, FromTable, NoComment, NoEpilog, NoFrom, NoWhere,
  OrWhere, XorWhere,
}
import cake/internal/write_query.{
  type Update, type UpdateFrom, type UpdateSet, type UpdateSets, type WriteQuery,
  NoReturning, NoUpdateFrom, NoUpdateModifier, Returning, Update,
  UpdateExpressionSet, UpdateFrom, UpdateFromWithJoins, UpdateParamSet,
  UpdateQuery, UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{type Param}
import gleam/list
import gleam/string

/// Creates a `WriteQuery` from an `Update`.
///
pub fn to_query(update updt: Update(a)) -> WriteQuery(a) {
  updt |> UpdateQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

pub fn bool(value vl: Bool) -> Param {
  vl |> param.bool
}

pub fn float(value vl: Float) -> Param {
  vl |> param.float
}

pub fn int(value vl: Int) -> Param {
  vl |> param.int
}

pub fn string(value vl: String) -> Param {
  vl |> param.string
}

// ▒▒▒ Constructor ▒▒▒

pub fn new(table tbl: String, sets sts: List(UpdateSet)) -> Update(a) {
  Update(
    modifier: NoUpdateModifier,
    table: UpdateTable(tbl),
    set: UpdateSets(sts),
    from: NoUpdateFrom,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Set ▒▒▒

pub fn set_to_param(column col: String, param prm: Param) -> UpdateSet {
  UpdateParamSet(column: col, param: prm)
}

pub fn set_to_expression(
  column col: String,
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: [col], expression: exp)
}

pub fn set_to_sub_query(column col: String, sub_query qry: Query) -> UpdateSet {
  UpdateSubQuerySet(columns: [col], sub_query: qry)
}

pub fn set_many_to_expression(
  columns cols: List(String),
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: cols, expression: exp)
}

pub fn set_many_to_sub_query(
  columns cols: List(String),
  sub_query qry: Query,
) -> UpdateSet {
  UpdateSubQuerySet(columns: cols, sub_query: qry)
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Update` query to a table name.
///
/// In addition this specifies `Joins`.
///
pub fn from_table(query qry: Update(a), name tbl_nm: String) -> Update(a) {
  Update(..qry, from: FromTable(name: tbl_nm) |> UpdateFrom)
}

/// Sets the `FROM` clause of the `Update` query to a table name.
///
pub fn from_table_with_joins(
  query qry: Update(a),
  name tbl_nm: String,
  joins jns: Joins,
) -> Update(a) {
  Update(
    ..qry,
    from: FromTable(name: tbl_nm) |> UpdateFromWithJoins(joins: jns),
  )
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
pub fn from_sub_query(
  query qry: Update(a),
  sub_query sb_qry: Query,
  alias als: String,
) -> Update(a) {
  Update(..qry, from: FromSubQuery(sub_query: sb_qry, alias: als) |> UpdateFrom)
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
/// In addition this specifies `Joins`.
///
pub fn from_sub_query_with_joins(
  query qry: Update(a),
  sub_query sb_qry: Query,
  alias als: String,
  joins jns: Joins,
) -> Update(a) {
  Update(
    ..qry,
    from: FromSubQuery(sub_query: sb_qry, alias: als)
      |> UpdateFromWithJoins(joins: jns),
  )
}

/// Removes the `FROM` clause of the `Update` query.
///
pub fn no_from(query qry: Update(a)) -> Update(a) {
  Update(..qry, from: NoFrom |> UpdateFrom)
}

/// Gets the `FROM` clause of the `Update` query.
///
pub fn get_from(query qry: Update(a)) -> UpdateFrom {
  qry.from
}

// ▒▒▒ WHERE ▒▒▒

/// Sets an `AndWhere` or appends into an existing `AndWhere`.
///
/// - If the outermost `Where` is an `AndWhere`, the new `Where` is appended
///   to the list within `AndWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
pub fn where(query qry: Update(a), where whr: Where) -> Update(a) {
  case qry.where {
    NoWhere -> Update(..qry, where: whr)
    AndWhere(wheres) ->
      Update(..qry, where: AndWhere(wheres |> list.append([whr])))
    _ -> Update(..qry, where: AndWhere([qry.where, whr]))
  }
}

/// Sets an `OrWhere` or appends into an existing `OrWhere`.
///
/// - If the outermost `Where` is an `OrWhere`, the new `Where` is appended
///   to the list within `OrWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `OrWhere`.
///
pub fn or_where(query qry: Update(a), where whr: Where) -> Update(a) {
  case qry.where {
    NoWhere -> Update(..qry, where: whr)
    OrWhere(wheres) ->
      Update(..qry, where: OrWhere(wheres |> list.append([whr])))
    _ -> Update(..qry, where: OrWhere([qry.where, whr]))
  }
}

/// Sets an `XorWhere` or appends into an existing `XorWhere`.
///
/// - If the outermost `Where` is an `XorWhere`, the new `Where` is appended
///   to the list within `XorWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `XorWhere`.
///
/// NOTICE: This operator does not exist in Postgres or Sqlite,
///         and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
///         This operator exists in MariaDB/MySQL.
///
pub fn xor_where(query qry: Update(a), where whr: Where) -> Update(a) {
  case qry.where {
    NoWhere -> Update(..qry, where: whr)
    XorWhere(wheres) ->
      Update(..qry, where: XorWhere(wheres |> list.append([whr])))
    _ -> Update(..qry, where: XorWhere([qry.where, whr]))
  }
}

/// Replaces the `Where` in the `Update` query.
///
pub fn replace_where(query qry: Update(a), where whr: Where) -> Update(a) {
  Update(..qry, where: whr)
}

/// Removes the `Where` from the `Update` query.
///
pub fn no_where(query qry: Update(a)) -> Update(a) {
  Update(..qry, where: NoWhere)
}

/// Gets the `Where` of the `Update` query.
///
pub fn get_where(query qry: Update(a)) -> Where {
  qry.where
}

// ▒▒▒ RETURNING ▒▒▒

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
///         they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn returning(
  query qry: Update(a),
  returning rtrn: List(String),
) -> Update(a) {
  case rtrn {
    [] -> Update(..qry, returning: NoReturning)
    _ -> Update(..qry, returning: Returning(rtrn))
  }
}

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
///         they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(query qry: Update(a)) -> Update(a) {
  Update(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

pub fn epilog(query qry: Update(a), epilog eplg: String) -> Update(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Update(..qry, epilog: NoEpilog)
    _ -> Update(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn no_epilog(query qry: Update(a)) -> Update(a) {
  Update(..qry, epilog: NoEpilog)
}

pub fn get_epilog(query qry: Update(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

pub fn comment(query qry: Update(a), comment cmmnt: String) -> Update(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Update(..qry, comment: NoComment)
    _ -> Update(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

pub fn no_comment(query qry: Update(a)) -> Update(a) {
  Update(..qry, comment: NoComment)
}

pub fn get_comment(query qry: Update(a)) -> Comment {
  qry.comment
}
