//// A DSL to build `UPDATE` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type From, type Join, type Joins, type Query,
  type Where, AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins,
  NoComment, NoEpilog, NoFrom, NoJoins, NoWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  type Update, type UpdateSet, type UpdateSets, type UpdateTable,
  type WriteQuery, NoReturning, NoUpdateModifier, NoUpdateSets, NoUpdateTable,
  Returning, Update, UpdateExpressionSet, UpdateParamSet, UpdateQuery,
  UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{type Param}
import gleam/list
import gleam/string

/// Creates a `WriteQuery` from an `Update` query.
///
pub fn to_query(update updt: Update(a)) -> WriteQuery(a) {
  updt |> UpdateQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

/// Creates a `Param` from a `Bool`.
///
pub fn bool(value vl: Bool) -> Param {
  vl |> param.bool
}

/// Creates a `Param` from a `Float`.
///
pub fn float(value vl: Float) -> Param {
  vl |> param.float
}

/// Creates a `Param` from an `Int`.
///
pub fn int(value vl: Int) -> Param {
  vl |> param.int
}

/// Creates a `Param` from a `String`.
///
pub fn string(value vl: String) -> Param {
  vl |> param.string
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
pub fn table(query qry: Update(a), table_name tbl_nm: String) -> Update(a) {
  Update(..qry, table: UpdateTable(tbl_nm))
}

/// Get the table of the `Update` query.
///
pub fn get_table(query qry: Update(a)) -> UpdateTable {
  qry.table
}

// ▒▒▒ Set ▒▒▒

/// Sets a column to a param value.
///
pub fn set_to_param(column col: String, param prm: Param) -> UpdateSet {
  UpdateParamSet(column: col, param: prm)
}

/// Sets a column to an expression value.
///
pub fn set_to_expression(
  column col: String,
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: [col], expression: exp)
}

/// Sets a column to a sub-query value.
///
pub fn set_to_sub_query(column col: String, sub_query qry: Query) -> UpdateSet {
  UpdateSubQuerySet(columns: [col], sub_query: qry)
}

/// Sets or appends one columne set in an `Update` query.
///
pub fn set(query qry: Update(a), set st: UpdateSet) -> Update(a) {
  case qry.set {
    NoUpdateSets -> Update(..qry, set: UpdateSets([st]))
    UpdateSets(sets) ->
      Update(..qry, set: UpdateSets(sets |> list.append([st])))
  }
}

/// Sets or replaces one column set in an `Update` query.
///
pub fn set_replace(query qry: Update(a), set st: UpdateSet) -> Update(a) {
  Update(..qry, set: UpdateSets([st]))
}

/// Sets or appends many column sets n an `Update` query.
///
pub fn sets(query qry: Update(a), set sts: List(UpdateSet)) -> Update(a) {
  case qry.set {
    NoUpdateSets -> Update(..qry, set: UpdateSets(sts))
    UpdateSets(sets) -> Update(..qry, set: UpdateSets(sets |> list.append(sts)))
  }
}

/// Sets or replaces many column sets in an `Update` query.
///
pub fn sets_replace(
  query qry: Update(a),
  sets sts: List(UpdateSet),
) -> Update(a) {
  Update(..qry, set: UpdateSets(sts))
}

/// Sets many columns to an expression value.
///
/// NOTICE: the expression must return an equal count of columns.
///
pub fn set_many_to_expression(
  columns cols: List(String),
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: cols, expression: exp)
}

/// Sets many columns to a sub-query value.
///
/// NOTICE: the sub-query must return an equal count of columns.
///
pub fn set_many_to_sub_query(
  columns cols: List(String),
  sub_query qry: Query,
) -> UpdateSet {
  UpdateSubQuerySet(columns: cols, sub_query: qry)
}

/// Get the sets of the `Update` query.
///
pub fn get_sets(query qry: Update(a)) -> List(UpdateSet) {
  case qry.set {
    NoUpdateSets -> []
    UpdateSets(sets) -> sets
  }
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Update` query to a table name.
///
pub fn from_table(query qry: Update(a), name tbl_nm: String) -> Update(a) {
  Update(..qry, from: FromTable(name: tbl_nm))
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
pub fn from_sub_query(
  query qry: Update(a),
  sub_query sb_qry: Query,
  alias als: String,
) -> Update(a) {
  Update(..qry, from: FromSubQuery(sub_query: sb_qry, alias: als))
}

/// Removes the `FROM` clause of the `Update` query.
///
pub fn no_from(query qry: Update(a)) -> Update(a) {
  Update(..qry, from: NoFrom)
}

/// Gets the `FROM` clause of the `Update` query.
///
pub fn get_from(query qry: Update(a)) -> From {
  qry.from
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Update` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn join(query qry: Update(a), join jn: Join) -> Update(a) {
  case qry.join {
    Joins(jns) -> Update(..qry, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Update(..qry, join: [jn] |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with a signle `Join`.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_join(query qry: Update(a), join jn: Join) -> Update(a) {
  Update(..qry, join: [jn] |> Joins)
}

/// Adds `Join`s to the `Update` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn joins(query qry: Update(a), joins jns: List(Join)) -> Update(a) {
  case jns, qry.join {
    [], _ -> Update(..qry, join: Joins(jns))
    jns, Joins(qry_joins) ->
      Update(..qry, join: qry_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Update(..qry, join: jns |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with the given `Join`s.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_joins(query qry: Update(a), joins jns: List(Join)) -> Update(a) {
  Update(..qry, join: jns |> Joins)
}

/// Removes any `Joins` from the `Update` query.
///
pub fn no_join(query qry: Update(a)) -> Update(a) {
  Update(..qry, join: NoJoins)
}

/// Gets the `Joins` of the `Update` query.
///
pub fn get_joins(query qry: Update(a)) -> Joins {
  qry.join
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
/// NOTICE: This operator does not exist in Postgres or SQLite,
/// and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
/// This operator exists in MariaDB/MySQL.
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
/// they do support it in `INSERT` (and `REPLACE`) queries, however.
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
/// they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(query qry: Update(a)) -> Update(a) {
  Update(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Sets an `Epilog` or appends into an existing `Epilog`.
///
pub fn epilog(query qry: Update(a), epilog eplg: String) -> Update(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Update(..qry, epilog: NoEpilog)
    _ -> Update(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Update` query.
///
pub fn no_epilog(query qry: Update(a)) -> Update(a) {
  Update(..qry, epilog: NoEpilog)
}

/// Gets the `Epilog` of the `Update` query.
///
pub fn get_epilog(query qry: Update(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Sets a `Comment` or appends into an existing `Comment`.
///
pub fn comment(query qry: Update(a), comment cmmnt: String) -> Update(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Update(..qry, comment: NoComment)
    _ -> Update(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Removes the `Comment` from the `Update` query.
///
pub fn no_comment(query qry: Update(a)) -> Update(a) {
  Update(..qry, comment: NoComment)
}

/// Gets the `Comment` of the `Update` query.
///
pub fn get_comment(query qry: Update(a)) -> Comment {
  qry.comment
}
