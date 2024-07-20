//// A DSL to build `UPDATE` queries.
////

import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins, NoComment, NoEpilog,
  NoFrom, NoJoins, NoWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  NoReturning, NoUpdateModifier, NoUpdateSets, NoUpdateTable, Returning, Update,
  UpdateExpressionSet, UpdateParamSet, UpdateQuery, UpdateSets,
  UpdateSubQuerySet, UpdateTable,
}
import cake/param.{type Param, BoolParam, FloatParam, IntParam, StringParam}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Comment =
  read_query.Comment

pub type Epilog =
  read_query.Epilog

pub type From =
  read_query.From

pub type Join =
  read_query.Join

pub type Joins =
  read_query.Joins

pub type ReadQuery =
  read_query.ReadQuery

pub type Where =
  read_query.Where

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  write_query type re-exports                                              │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Update(a) =
  write_query.Update(a)

pub type UpdateSet =
  write_query.UpdateSet

pub type UpdateSets =
  write_query.UpdateSets

pub type UpdateTable =
  write_query.UpdateTable

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Creates a `WriteQuery` from an `Update` query.
///
pub fn to_query(update updt: Update(a)) -> WriteQuery(a) {
  updt |> UpdateQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

/// Creates a `Param` from a `Bool`.
///
pub fn bool(value vl: Bool) -> Param {
  vl |> BoolParam
}

/// Creates a `Param` from a `Float`.
///
pub fn float(value vl: Float) -> Param {
  vl |> FloatParam
}

/// Creates a `Param` from an `Int`.
///
pub fn int(value vl: Int) -> Param {
  vl |> IntParam
}

/// Creates a `Param` from a `String`.
///
pub fn string(value vl: String) -> Param {
  vl |> StringParam
}

// ▒▒▒ Constructor ▒▒▒

/// Creates an empty `Update` query.
///
pub fn new() -> Update(a) {
  Update(
    modifier: NoUpdateModifier,
    table: NoUpdateTable,
    set: NoUpdateSets,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Sets the table of the `Update` query.
///
pub fn table(update updt: Update(a), table_name tbl_nm: String) -> Update(a) {
  Update(..updt, table: tbl_nm |> UpdateTable)
}

/// Get the table of the `Update` query.
///
pub fn get_table(update updt: Update(a)) -> UpdateTable {
  updt.table
}

// ▒▒▒ Set ▒▒▒

/// Sets a column to a param value.
///
pub fn set_to_param(column col: String, param prm: Param) -> UpdateSet {
  col |> UpdateParamSet(param: prm)
}

/// Sets a column to an expression value.
///
pub fn set_to_expression(
  column col: String,
  expression exp: String,
) -> UpdateSet {
  [col] |> UpdateExpressionSet(expression: exp)
}

/// Sets a column to a sub-query value.
///
pub fn set_to_sub_query(column col: String, query qry: ReadQuery) -> UpdateSet {
  [col] |> UpdateSubQuerySet(query: qry)
}

/// Sets or appends one columne set in an `Update` query.
///
pub fn set(update updt: Update(a), set st: UpdateSet) -> Update(a) {
  case updt.set {
    NoUpdateSets -> Update(..updt, set: [st] |> UpdateSets)
    UpdateSets(sets) ->
      Update(..updt, set: sets |> list.append([st]) |> UpdateSets)
  }
}

/// Sets or replaces one column set in an `Update` query.
///
pub fn set_replace(update updt: Update(a), set st: UpdateSet) -> Update(a) {
  Update(..updt, set: [st] |> UpdateSets)
}

/// Sets or appends many column sets n an `Update` query.
///
pub fn sets(update updt: Update(a), set sts: List(UpdateSet)) -> Update(a) {
  case updt.set {
    NoUpdateSets -> Update(..updt, set: sts |> UpdateSets)
    UpdateSets(sets) ->
      Update(..updt, set: sets |> list.append(sts) |> UpdateSets)
  }
}

/// Sets or replaces many column sets in an `Update` query.
///
pub fn sets_replace(
  update updt: Update(a),
  sets sts: List(UpdateSet),
) -> Update(a) {
  Update(..updt, set: sts |> UpdateSets)
}

/// Sets many columns to an expression value.
///
/// NOTICE: the expression must return an equal count of columns.
///
pub fn sets_to_expression(
  columns cols: List(String),
  expression exp: String,
) -> UpdateSet {
  cols |> UpdateExpressionSet(expression: exp)
}

/// Sets many columns to a sub-query value.
///
/// NOTICE: the sub-query must return an equal count of columns.
///
pub fn sets_to_sub_query(
  columns cols: List(String),
  query qry: ReadQuery,
) -> UpdateSet {
  cols |> UpdateSubQuerySet(query: qry)
}

/// Get the sets of the `Update` query.
///
pub fn get_set(update updt: Update(a)) -> List(UpdateSet) {
  case updt.set {
    NoUpdateSets -> []
    UpdateSets(sets) -> sets
  }
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Update` query to a table name.
///
pub fn from_table(update updt: Update(a), name tbl_nm: String) -> Update(a) {
  Update(..updt, from: tbl_nm |> FromTable)
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
pub fn from_sub_query(
  update updt: Update(a),
  query qry: ReadQuery,
  alias als: String,
) -> Update(a) {
  Update(..updt, from: qry |> FromSubQuery(alias: als))
}

/// Removes the `FROM` clause of the `Update` query.
///
pub fn no_from(update updt: Update(a)) -> Update(a) {
  Update(..updt, from: NoFrom)
}

/// Gets the `FROM` clause of the `Update` query.
///
pub fn get_from(update updt: Update(a)) -> From {
  updt.from
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Update` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn join(update updt: Update(a), join jn: Join) -> Update(a) {
  case updt.join {
    Joins(jns) -> Update(..updt, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Update(..updt, join: [jn] |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with a signle `Join`.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_join(update updt: Update(a), join jn: Join) -> Update(a) {
  Update(..updt, join: [jn] |> Joins)
}

/// Adds `Join`s to the `Update` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn joins(update updt: Update(a), joins jns: List(Join)) -> Update(a) {
  case jns, updt.join {
    [], _ -> Update(..updt, join: jns |> Joins)
    jns, Joins(updt_joins) ->
      Update(..updt, join: updt_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Update(..updt, join: jns |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with the given `Join`s.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_joins(update updt: Update(a), joins jns: List(Join)) -> Update(a) {
  Update(..updt, join: jns |> Joins)
}

/// Removes any `Joins` from the `Update` query.
///
pub fn no_join(update updt: Update(a)) -> Update(a) {
  Update(..updt, join: NoJoins)
}

/// Gets the `Joins` of the `Update` query.
///
pub fn get_joins(update updt: Update(a)) -> Joins {
  updt.join
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
pub fn where(update updt: Update(a), where whr: Where) -> Update(a) {
  case updt.where {
    NoWhere -> Update(..updt, where: whr)
    AndWhere(wheres) ->
      Update(..updt, where: wheres |> list.append([whr]) |> AndWhere)
    _ -> Update(..updt, where: [updt.where, whr] |> AndWhere)
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
pub fn or_where(update updt: Update(a), where whr: Where) -> Update(a) {
  case updt.where {
    NoWhere -> Update(..updt, where: whr)
    OrWhere(wheres) ->
      Update(..updt, where: wheres |> list.append([whr]) |> OrWhere)
    _ -> Update(..updt, where: [updt.where, whr] |> OrWhere)
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
/// NOTICE: This operator does not exist in Postgres or SQLite,
/// and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
/// This operator exists in MariaDB/MySQL.
///
pub fn xor_where(update updt: Update(a), where whr: Where) -> Update(a) {
  case updt.where {
    NoWhere -> Update(..updt, where: whr)
    XorWhere(wheres) ->
      Update(..updt, where: wheres |> list.append([whr]) |> XorWhere)
    _ -> Update(..updt, where: [updt.where, whr] |> XorWhere)
  }
}

/// Replaces the `Where` in the `Update` query.
///
pub fn replace_where(update updt: Update(a), where whr: Where) -> Update(a) {
  Update(..updt, where: whr)
}

/// Removes the `Where` from the `Update` query.
///
pub fn no_where(update updt: Update(a)) -> Update(a) {
  Update(..updt, where: NoWhere)
}

/// Gets the `Where` of the `Update` query.
///
pub fn get_where(update updt: Update(a)) -> Where {
  updt.where
}

// ▒▒▒ RETURNING ▒▒▒

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
/// they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn returning(
  update updt: Update(a),
  returning rtrn: List(String),
) -> Update(a) {
  case rtrn {
    [] -> Update(..updt, returning: NoReturning)
    _ -> Update(..updt, returning: rtrn |> Returning)
  }
}

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
/// they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(update updt: Update(a)) -> Update(a) {
  Update(..updt, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Sets an `Epilog` or appends into an existing `Epilog`.
///
pub fn epilog(update updt: Update(a), epilog eplg: String) -> Update(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Update(..updt, epilog: NoEpilog)
    _ -> Update(..updt, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Update` query.
///
pub fn no_epilog(update updt: Update(a)) -> Update(a) {
  Update(..updt, epilog: NoEpilog)
}

/// Gets the `Epilog` of the `Update` query.
///
pub fn get_epilog(update updt: Update(a)) -> Epilog {
  updt.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Sets a `Comment` or appends into an existing `Comment`.
///
pub fn comment(update updt: Update(a), comment cmmnt: String) -> Update(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Update(..updt, comment: NoComment)
    _ -> Update(..updt, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Removes the `Comment` from the `Update` query.
///
pub fn no_comment(update updt: Update(a)) -> Update(a) {
  Update(..updt, comment: NoComment)
}

/// Gets the `Comment` of the `Update` query.
///
pub fn get_comment(update updt: Update(a)) -> Comment {
  updt.comment
}
