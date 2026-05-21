//// A DSL to build `SELECT` queries.
////

import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, GroupBy, Joins, NoComment,
  NoEpilog, NoFrom, NoGroupBy, NoJoins, NoLimit, NoOffset, NoOrderBy, NoSelects,
  NoWhere, OrWhere, OrderBy, OrderByColumn, Select, SelectAlias, SelectAll,
  SelectColumn, SelectDistinct, SelectFragment, SelectParam, SelectQuery,
  Selects, XorWhere,
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

pub type Fragment =
  read_query.Fragment

pub type From =
  read_query.From

pub type GroupBy =
  read_query.GroupBy

pub type Join =
  read_query.Join

pub type Joins =
  read_query.Joins

pub type Limit =
  read_query.Limit

pub type Offset =
  read_query.Offset

pub type OrderBy =
  read_query.OrderBy

pub type OrderByDirection =
  read_query.OrderByDirection

pub type ReadQuery =
  read_query.ReadQuery

pub type Select =
  read_query.Select

pub type SelectKind =
  read_query.SelectKind

pub type SelectValue =
  read_query.SelectValue

pub type Selects =
  read_query.Selects

pub type Where =
  read_query.Where

/// Creates a `ReadQuery` from a `Select` query.
///
pub fn to_query(select select: Select) -> ReadQuery {
  select |> SelectQuery
}

/// Creates a column `SelectValue` from a `String`.
///
pub fn col(name name: String) -> SelectValue {
  name |> SelectColumn
}

/// Creates an alias `SelectValue` from `String`.
///
pub fn alias(value value: SelectValue, alias alias: String) -> SelectValue {
  value |> SelectAlias(alias:)
}

/// Creates a `SelectValue` from a `Bool`.
///
pub fn bool(value value: Bool) -> SelectValue {
  value |> BoolParam |> SelectParam
}

/// Creates a `SelectValue` from a `Float`.
///
pub fn float(value value: Float) -> SelectValue {
  value |> FloatParam |> SelectParam
}

/// Creates a `SelectValue` from an `Int`.
///
pub fn int(value value: Int) -> SelectValue {
  value |> IntParam |> SelectParam
}

/// Creates a `SelectValue` from a `String`.
///
pub fn string(value value: String) -> SelectValue {
  value |> StringParam |> SelectParam
}

/// Creates a `SelectValue` from a `calendar.Date`.
///
pub fn date(v value: calendar.Date) -> SelectValue {
  value |> DateParam |> SelectParam
}

/// Creates an SQL `NULL` `Param`.
///
pub fn null() -> SelectValue {
  NullParam |> SelectParam
}

/// Creates a `SelectFragment` off a `Fragment`.
pub fn fragment(fragment fragment: Fragment) -> SelectValue {
  fragment |> SelectFragment
}

// ▒▒▒ NEW ▒▒▒

/// Creates an empty `Select` query.
///
pub fn new() -> Select {
  Select(
    kind: SelectAll,
    select: NoSelects,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit: NoLimit,
    offset: NoOffset,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ KIND ▒▒▒

/// Sets the kind of the `Select` query to
/// return duplicates which is the default.
///
pub fn all(select select: Select) -> Select {
  Select(..select, kind: SelectAll)
}

/// Sets the kind of the `Select` query to
/// return distinct rows only.
///
pub fn distinct(select select: Select) -> Select {
  Select(..select, kind: SelectDistinct)
}

/// Gets the kind of the `Select` query.
///
pub fn get_kind(select select: Select) -> SelectKind {
  select.kind
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Select` query to a table name.
///
pub fn from_table(select select: Select, name table_name: String) -> Select {
  Select(..select, from: table_name |> FromTable)
}

/// Sets the `FROM` clause of the `Select` query to an aliased sub-query.
///
pub fn from_query(
  select select: Select,
  sub_query sub_query: ReadQuery,
  alias alias: String,
) -> Select {
  Select(..select, from: sub_query |> FromSubQuery(alias:))
}

/// Removes the `FROM` clause of the `Select` query.
///
pub fn no_from(select select: Select) -> Select {
  Select(..select, from: NoFrom)
}

/// Gets the `FROM` clause of the `Select` query.
///
pub fn get_from(select select: Select) -> From {
  select.from
}

// ▒▒▒ SELECT ▒▒▒

/// Add a column name to the `Select` query as a `SelectValue`.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select_col(select select: Select, name name: String) -> Select {
  let select_value = name |> col
  case select.select {
    NoSelects -> Select(..select, select: [select_value] |> Selects)
    Selects(existing_selects) ->
      Select(
        ..select,
        select: existing_selects |> list.append([select_value]) |> Selects,
      )
  }
}

/// Add a `SelectValue` to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select(
  select select: Select,
  select_value select_value: SelectValue,
) -> Select {
  case select.select {
    NoSelects -> Select(..select, select: [select_value] |> Selects)
    Selects(existing_selects) ->
      Select(
        ..select,
        select: existing_selects |> list.append([select_value]) |> Selects,
      )
  }
}

/// Add a column name to the `Select` query as a `SelectValue`.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select_col(select select: Select, name name: String) -> Select {
  name |> col |> replace_select(select:)
}

/// Add a `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select(
  select select: Select,
  select_value select_value: SelectValue,
) -> Select {
  case select.select {
    NoSelects -> Select(..select, select: [select_value] |> Selects)
    Selects(_) -> Select(..select, select: [select_value] |> Selects)
  }
}

/// Adds many column names as `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn select_cols(
  select select: Select,
  select_cols columns: List(String),
) -> Select {
  columns |> list.map(col) |> selects(select:)
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn selects(
  select select: Select,
  select_values select_values: List(SelectValue),
) -> Select {
  case select_values, select.select {
    [], _ -> select
    select_values, NoSelects ->
      Select(..select, select: select_values |> Selects)
    select_values, Selects(existing_selects) ->
      Select(
        ..select,
        select: existing_selects |> list.append(select_values) |> Selects,
      )
  }
}

/// Adds many column names as `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are replaced.
///
pub fn replace_select_cols(
  select select: Select,
  select_cols columns: List(String),
) -> Select {
  columns |> list.map(col) |> replace_selects(select:)
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_selects(
  select select: Select,
  select_values select_values: List(SelectValue),
) -> Select {
  case select_values, select.select {
    [], _ -> select
    select_values, NoSelects ->
      Select(..select, select: select_values |> Selects)
    select_values, Selects(_) ->
      Select(..select, select: select_values |> Selects)
  }
}

/// Gets the `SelectValue`s of the `Select` query.
///
pub fn get_select(select select: Select) -> Selects {
  select.select
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Select` query.
///
pub fn join(select select: Select, join join: Join) -> Select {
  case select.join {
    Joins(joins) ->
      Select(..select, join: joins |> list.append([join]) |> Joins)
    NoJoins -> Select(..select, join: [join] |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with a signle `Join`.
///
pub fn replace_join(select select: Select, join join: Join) -> Select {
  Select(..select, join: [join] |> Joins)
}

/// Adds `Join`s to the `Select` query.
///
pub fn joins(select select: Select, joins joins: List(Join)) -> Select {
  case joins, select.join {
    [], _ -> Select(..select, join: joins |> Joins)
    joins, Joins(existing_joins) ->
      Select(..select, join: existing_joins |> list.append(joins) |> Joins)
    joins, NoJoins -> Select(..select, join: joins |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with the given `Join`s.
///
pub fn replace_joins(select select: Select, joins joins: List(Join)) -> Select {
  Select(..select, join: joins |> Joins)
}

/// Removes any `Joins` from the `Select` query.
///
pub fn no_join(select select: Select) -> Select {
  Select(..select, join: NoJoins)
}

/// Gets the `Joins` of the `Select` query.
///
pub fn get_joins(select select: Select) -> Joins {
  select.join
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
pub fn where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    AndWhere(wheres) ->
      Select(..select, where: wheres |> list.append([where]) |> AndWhere)
    _ -> Select(..select, where: [select.where, where] |> AndWhere)
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
pub fn or_where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    OrWhere(wheres) ->
      Select(..select, where: wheres |> list.append([where]) |> OrWhere)
    _ -> Select(..select, where: [select.where, where] |> OrWhere)
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
/// This operator exists in 🦭MariaDB and 🐬MySQL.
///
pub fn xor_where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    XorWhere(wheres) ->
      Select(..select, where: wheres |> list.append([where]) |> XorWhere)
    _ -> Select(..select, where: [select.where, where] |> XorWhere)
  }
}

/// Replaces the `Where` in the `Select` query.
///
pub fn replace_where(select select: Select, where where: Where) -> Select {
  Select(..select, where:)
}

/// Removes the `Where` from the `Select` query.
///
pub fn no_where(select select: Select) -> Select {
  Select(..select, where: NoWhere)
}

/// Gets the `Where` of the `Select` query.
///
pub fn get_where(select select: Select) -> Where {
  select.where
}

// ▒▒▒ HAVING ▒▒▒

/// Sets an `AndWhere` or appends into an existing `AndWhere`.
///
/// - If the outermost `Where` is an `AndWhere`, the new `Where` is appended
///   to the list within `AndWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
/// NOTICE: `HAVING` allows to specify constraints much like `WHERE`, but
/// filters the results after `GROUP BY` is applied instead of before. Because
/// `HAVING` uses the same semantics as `WHERE`, it
///         takes a `Where`.
///
pub fn having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    AndWhere(wheres) ->
      Select(..select, having: wheres |> list.append([where]) |> AndWhere)
    _ -> Select(..select, having: [select.having, where] |> AndWhere)
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
/// See function `having` on details why this takes a `Where`.
///
pub fn or_having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    OrWhere(wheres) ->
      Select(..select, having: wheres |> list.append([where]) |> OrWhere)
    _ -> Select(..select, having: [select.having, where] |> OrWhere)
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
/// See function `having` on details why this takes a `Where`.
///
/// NOTICE: This operator does not exist in 🐘PostgreSQL or 🪶SQLite,
/// and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
/// This operator exists in 🦭MariaDB and 🐬MySQL.
///
pub fn xor_having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    XorWhere(wheres) ->
      Select(..select, having: wheres |> list.append([where]) |> XorWhere)
    _ -> Select(..select, having: [select.having, where] |> XorWhere)
  }
}

/// Replaces `HAVING` in the `Select` query.
///
/// See function `having` on details why this takes a `Where`.
///
pub fn replace_having(select select: Select, having where: Where) -> Select {
  Select(..select, having: where)
}

/// Removes `HAVING` from the `Select` query.
///
pub fn no_having(select select: Select) -> Select {
  Select(..select, having: NoWhere)
}

/// Gets`HAVING` in the `Select` query.
///
/// See function `having` on details why this returns a `Where`.
///
pub fn get_having(select select: Select) -> Where {
  select.having
}

// ▒▒▒ GROUP BY ▒▒▒

/// Sets or appends `GroupBy` a single into an existing `GroupBy`.
///
pub fn group_by(select select: Select, group_by group_by: String) -> Select {
  case select.group_by {
    NoGroupBy -> Select(..select, group_by: [group_by] |> GroupBy)
    GroupBy(group_bys) ->
      Select(
        ..select,
        group_by: group_bys |> list.append([group_by]) |> GroupBy,
      )
  }
}

/// Replaces `GroupBy` with a single `GroupBy`.
///
pub fn replace_group_by(
  select select: Select,
  group_by group_by: String,
) -> Select {
  Select(..select, group_by: [group_by] |> GroupBy)
}

/// Sets or appends a list of `GroupBy` into an existing `GroupBy`.
///
pub fn group_bys(
  select select: Select,
  group_bys group_bys: List(String),
) -> Select {
  case select.group_by {
    NoGroupBy -> Select(..select, group_by: group_bys |> GroupBy)
    GroupBy(existing_group_bys) ->
      Select(
        ..select,
        group_by: existing_group_bys |> list.append(group_bys) |> GroupBy,
      )
  }
}

/// Replaces `GroupBy` with a list of `GroupBy`s.
///
pub fn replace_group_bys(
  select select: Select,
  group_bys group_bys: List(String),
) -> Select {
  Select(..select, group_by: group_bys |> GroupBy)
}

/// Removes `GroupBy` from the `Select` query.
///
pub fn no_group_by(select select: Select) -> Select {
  Select(..select, group_by: NoGroupBy)
}

/// Gets `GroupBy` in the `Select` query.
///
pub fn get_group_by(select select: Select) -> GroupBy {
  select.group_by
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Select` query.
///
pub fn limit(select select: Select, limit limit: Int) -> Select {
  let limit = limit |> read_query.limit_new
  Select(..select, limit:)
}

/// Removes `Limit` from the `Select` query.
///
pub fn no_limit(select select: Select) -> Select {
  Select(..select, limit: NoLimit)
}

/// Gets `Limit` in the `Select` query.
///
pub fn get_limit(select select: Select) -> Limit {
  select.limit
}

/// Sets an `Offset` in the `Select` query.
///
pub fn offset(select select: Select, offset offset: Int) -> Select {
  let offset = offset |> read_query.offset_new
  Select(..select, offset:)
}

/// Removes `Offset` from the `Select` query.
///
pub fn no_offset(select select: Select) -> Select {
  Select(..select, offset: NoOffset)
}

/// Gets `Offset` in the `Select` query.
///
pub fn get_offset(select select: Select) -> Offset {
  select.offset
}

// ▒▒▒ ORDER BY ▒▒▒

// FIXME: This should be reexported from `read_query` once gleam allows it.
//
/// Defines the direction of an `OrderBy`.
///
pub type Direction {
  Asc
  Desc
}

fn map_order_by_direction_constructor(in: Direction) -> OrderByDirection {
  case in {
    Asc -> read_query.Asc
    Desc -> read_query.Desc
  }
}

/// Creates or appends an ascending `OrderBy`.
///
pub fn order_by_asc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Asc)]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_asc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [
      order_by |> OrderByColumn(direction: read_query.AscNullsFirst),
    ]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsFirst)]
      |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Asc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_asc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_asc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_desc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_desc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single descending order.
///
pub fn replace_order_by_desc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_desc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_desc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Creates or appends an `OrderBy` a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  select select: Select,
  order_by order_by: String,
  direction direction: Direction,
) -> Select {
  let direction = direction |> map_order_by_direction_constructor
  select
  |> read_query.select_order_by(
    [order_by |> OrderByColumn(direction)] |> OrderBy,
    True,
  )
}

/// Replaces the `OrderBy` a column with a direction.
///
pub fn replace_order_by(
  select select: Select,
  order_by order_by: String,
  direction direction: Direction,
) -> Select {
  let direction = direction |> map_order_by_direction_constructor
  select
  |> read_query.select_order_by(
    [order_by |> OrderByColumn(direction)] |> OrderBy,
    False,
  )
}

/// Removes the `OrderBy` from the `Select` query.
///
pub fn no_order_by(select select: Select) -> Select {
  Select(..select, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Select` query.
///
pub fn get_order_by(select select: Select) -> OrderBy {
  select.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Select` query.
///
pub fn epilog(select select: Select, epilog epilog: String) -> Select {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Select(..select, epilog: NoEpilog)
    _ -> Select(..select, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Select` query.
///
pub fn no_epilog(select select: Select) -> Select {
  Select(..select, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Select` query.
///
pub fn get_epilog(select select: Select) -> Epilog {
  select.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Select` query.
///
pub fn comment(select select: Select, comment comment: String) -> Select {
  let comment = comment |> string.trim
  case comment {
    "" -> Select(..select, comment: NoComment)
    _ -> Select(..select, comment: { " " <> comment } |> Comment)
  }
}

/// Removes the `Comment` from the `Select` query.
///
pub fn no_comment(select select: Select) -> Select {
  Select(..select, comment: NoComment)
}

/// Gets the `Comment` from the `Select` query.
///
pub fn get_comment(select select: Select) -> Comment {
  select.comment
}
