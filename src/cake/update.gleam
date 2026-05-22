//// A DSL to build `UPDATE` queries.
////

import cake/fragment.{type Fragment}
import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins, NoComment, NoEpilog,
  NoFrom, NoJoins, NoWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  NoReturning, NoUpdateModifier, NoUpdateSets, NoUpdateTable, Returning, Update,
  UpdateExpressionSet, UpdateFragmentSet, UpdateParamSet, UpdateQuery,
  UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{
  BoolParam, DateParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/list
import gleam/string
import gleam/time/calendar

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
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
// │ write_query type re-exports                                               │
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
pub fn to_query(update update: Update(a)) -> WriteQuery(a) {
  update |> UpdateQuery
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
pub fn table(
  update update: Update(a),
  table_name table_name: String,
) -> Update(a) {
  Update(..update, table: table_name |> UpdateTable)
}

/// Get the table of the `Update` query.
///
pub fn get_table(update update: Update(a)) -> UpdateTable {
  update.table
}

// ▒▒▒ Set ▒▒▒

/// Sets a column to a `Bool` `UpdateParamSet`.
///
pub fn set_bool(column column: String, value value: Bool) -> UpdateSet {
  value |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `True` `UpdateParamSet`.
///
pub fn set_true(column column: String) -> UpdateSet {
  True |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `False` `UpdateParamSet`.
///
pub fn set_false(column column: String) -> UpdateSet {
  False |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `Float` `UpdateParamSet`.
///
pub fn set_float(column column: String, value value: Float) -> UpdateSet {
  value |> FloatParam |> UpdateParamSet(column:)
}

/// Sets a column to a `Int` `UpdateParamSet`.
///
pub fn set_int(column column: String, value value: Int) -> UpdateSet {
  value |> IntParam |> UpdateParamSet(column:)
}

/// Sets a column to a string `UpdateParamSet`.
///
pub fn set_string(column column: String, value value: String) -> UpdateSet {
  value |> StringParam |> UpdateParamSet(column:)
}

/// Sets a column to an SQL `NULL` `UpdateParamSet`.
///
pub fn set_null(column column: String) -> UpdateSet {
  NullParam |> UpdateParamSet(column:)
}

/// Sets a column to a `calendar.Date` `UpdateParamSet`.
///
pub fn set_date(column column: String, date date: calendar.Date) -> UpdateSet {
  date |> DateParam |> UpdateParamSet(column:)
}

/// Sets a column to an expression value.
///
pub fn set_expression(
  column column: String,
  expression expression: String,
) -> UpdateSet {
  [column] |> UpdateExpressionSet(expression:)
}

/// Sets a column to a sub-query value.
///
pub fn set_sub_query(
  column column: String,
  query query: ReadQuery,
) -> UpdateSet {
  [column] |> UpdateSubQuerySet(query:)
}

/// Sets a column to a fragment value with parameter binding.
///
/// ## Example
///
/// ```gleam
/// import cake/fragment as f
/// import cake/update as u
///
/// "org_id" |> u.set_fragment(f.prepared("$::uuid", [f.string("0000000000-0000-4000-a000-a00000000000")]))
/// ```
///
pub fn set_fragment(
  column column: String,
  fragment fragment: Fragment,
) -> UpdateSet {
  UpdateFragmentSet(column:, fragment:)
}

/// Sets many columns to an expression value.
///
/// NOTICE: the expression must return an equal count of columns.
///
pub fn sets_expression(
  columns columns: List(String),
  expression expression: String,
) -> UpdateSet {
  columns |> UpdateExpressionSet(expression:)
}

/// Sets many columns to a sub-query value.
///
/// NOTICE: the sub-query must return an equal count of columns.
///
pub fn sets_sub_query(
  columns columns: List(String),
  query query: ReadQuery,
) -> UpdateSet {
  columns |> UpdateSubQuerySet(query:)
}

/// Get the `SET`s of the `Update` query.
///
pub fn get_set(update update: Update(a)) -> List(UpdateSet) {
  case update.set {
    NoUpdateSets -> []
    UpdateSets(update_sets:) -> update_sets
  }
}

/// Sets or appends one column set in an `Update` query.
///
pub fn set(update update: Update(a), set set: UpdateSet) -> Update(a) {
  case update.set {
    NoUpdateSets -> Update(..update, set: [set] |> UpdateSets)
    UpdateSets(update_sets) ->
      Update(..update, set: update_sets |> list.append([set]) |> UpdateSets)
  }
}

/// Sets or replaces one column set in an `Update` query.
///
pub fn set_replace(update update: Update(a), set set: UpdateSet) -> Update(a) {
  Update(..update, set: [set] |> UpdateSets)
}

/// Sets or appends many column sets in an `Update` query.
///
pub fn sets(update update: Update(a), set sets: List(UpdateSet)) -> Update(a) {
  case update.set {
    NoUpdateSets -> Update(..update, set: sets |> UpdateSets)
    UpdateSets(update_sets:) ->
      Update(..update, set: update_sets |> list.append(sets) |> UpdateSets)
  }
}

/// Sets or replaces many column sets in an `Update` query.
///
pub fn sets_replace(
  update update: Update(a),
  sets sets: List(UpdateSet),
) -> Update(a) {
  Update(..update, set: sets |> UpdateSets)
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Update` query to a table name.
///
pub fn from_table(
  update update: Update(a),
  name table_name: String,
) -> Update(a) {
  Update(..update, from: table_name |> FromTable)
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
pub fn from_sub_query(
  update update: Update(a),
  query query: ReadQuery,
  alias alias: String,
) -> Update(a) {
  Update(..update, from: query |> FromSubQuery(alias:))
}

/// Removes the `FROM` clause of the `Update` query.
///
pub fn no_from(update update: Update(a)) -> Update(a) {
  Update(..update, from: NoFrom)
}

/// Gets the `FROM` clause of the `Update` query.
///
pub fn get_from(update update: Update(a)) -> From {
  update.from
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Update` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn join(update update: Update(a), join join: Join) -> Update(a) {
  case update.join {
    Joins(joins: existing_joins) ->
      Update(..update, join: existing_joins |> list.append([join]) |> Joins)
    NoJoins -> Update(..update, join: [join] |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with a single `Join`.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_join(update update: Update(a), join join: Join) -> Update(a) {
  Update(..update, join: [join] |> Joins)
}

/// Adds `Join`s to the `Update` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn joins(update update: Update(a), joins joins: List(Join)) -> Update(a) {
  case joins, update.join {
    [], _ -> update
    _, Joins(joins: existing_joins) ->
      Update(..update, join: existing_joins |> list.append(joins) |> Joins)
    _, NoJoins -> Update(..update, join: joins |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with the given `Join`s.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_joins(
  update update: Update(a),
  joins joins: List(Join),
) -> Update(a) {
  Update(..update, join: joins |> Joins)
}

/// Removes any `Joins` from the `Update` query.
///
pub fn no_join(update update: Update(a)) -> Update(a) {
  Update(..update, join: NoJoins)
}

/// Gets the `Joins` of the `Update` query.
///
pub fn get_joins(update update: Update(a)) -> Joins {
  update.join
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
pub fn where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    AndWhere(wheres) ->
      Update(..update, where: wheres |> list.append([where]) |> AndWhere)
    _ -> Update(..update, where: [update.where, where] |> AndWhere)
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
pub fn or_where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    OrWhere(wheres) ->
      Update(..update, where: wheres |> list.append([where]) |> OrWhere)
    _ -> Update(..update, where: [update.where, where] |> OrWhere)
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
/// NOTICE: This operator does not exist in 🐘PostgreSQL or 🪶SQLite,
/// and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
///
/// NOTICE: This operator exists in 🦭MariaDB and 🐬MySQL with native support.
///
pub fn xor_where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    XorWhere(wheres) ->
      Update(..update, where: wheres |> list.append([where]) |> XorWhere)
    _ -> Update(..update, where: [update.where, where] |> XorWhere)
  }
}

/// Replaces the `Where` in the `Update` query.
///
pub fn replace_where(
  update update: Update(a),
  where where: Where,
) -> Update(a) {
  Update(..update, where:)
}

/// Removes the `Where` from the `Update` query.
///
pub fn no_where(update update: Update(a)) -> Update(a) {
  Update(..update, where: NoWhere)
}

/// Gets the `Where` of the `Update` query.
///
pub fn get_where(update update: Update(a)) -> Where {
  update.where
}

// ▒▒▒ RETURNING ▒▒▒

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `RETURNING` in `UPDATE`
/// queries; they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn returning(
  update update: Update(a),
  returning returning: List(String),
) -> Update(a) {
  case returning {
    [] -> Update(..update, returning: NoReturning)
    _ -> Update(..update, returning: returning |> Returning)
  }
}

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `RETURNING` in `UPDATE`
/// queries; they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(update update: Update(a)) -> Update(a) {
  Update(..update, returning: NoReturning)
}

// ▒▒▒ Epilogue ▒▒▒

/// Sets an `Epilog` or appends into an existing `Epilog`.
///
pub fn epilog(update update: Update(a), epilog epilog: String) -> Update(a) {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Update(..update, epilog: NoEpilog)
    _ -> Update(..update, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Update` query.
///
pub fn no_epilog(update update: Update(a)) -> Update(a) {
  Update(..update, epilog: NoEpilog)
}

/// Gets the `Epilog` of the `Update` query.
///
pub fn get_epilog(update update: Update(a)) -> Epilog {
  update.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Sets a `Comment` or appends into an existing `Comment`.
///
pub fn comment(update update: Update(a), comment comment: String) -> Update(a) {
  let comment = comment |> string.trim
  case comment {
    "" -> Update(..update, comment: NoComment)
    _ -> Update(..update, comment: { " " <> comment } |> Comment)
  }
}

/// Removes the `Comment` from the `Update` query.
///
pub fn no_comment(update update: Update(a)) -> Update(a) {
  Update(..update, comment: NoComment)
}

/// Gets the `Comment` of the `Update` query.
///
pub fn get_comment(update update: Update(a)) -> Comment {
  update.comment
}
