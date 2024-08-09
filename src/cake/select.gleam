//// A DSL to build `SELECT` queries.
////

import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, GroupBy, Joins, Limit,
  NoComment, NoEpilog, NoFrom, NoGroupBy, NoJoins, NoLimit, NoOffset, NoOrderBy,
  NoSelects, NoWhere, Offset, OrWhere, OrderBy, OrderByColumn, Select,
  SelectAlias, SelectAll, SelectColumn, SelectDistinct, SelectFragment,
  SelectParam, SelectQuery, Selects, XorWhere,
}
import cake/param.{BoolParam, FloatParam, IntParam, NullParam, StringParam}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
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
pub fn to_query(select slct: Select) -> ReadQuery {
  slct |> SelectQuery
}

/// Creates a column identifier off a `String`.
///
pub fn col(name nm: String) -> SelectValue {
  nm |> SelectColumn
}

/// Creates an alias off a `String`.
///
pub fn alias(value vl: SelectValue, alias als: String) -> SelectValue {
  vl |> SelectAlias(alias: als)
}

/// Creates a boolean `Param` off a `Bool`.
///
pub fn bool(value vl: Bool) -> SelectValue {
  vl |> BoolParam |> SelectParam
}

/// Creates a float `Param` off a `Float`.
///
pub fn float(value vl: Float) -> SelectValue {
  vl |> FloatParam |> SelectParam
}

/// Creates an integer `Param` off an `Int`.
///
pub fn int(value vl: Int) -> SelectValue {
  vl |> IntParam |> SelectParam
}

/// Creates a string `Param` off a `String`.
///
pub fn string(value vl: String) -> SelectValue {
  vl |> StringParam |> SelectParam
}

/// Creates an SQL `NULL` `Param`.
///
pub fn null() -> SelectValue {
  NullParam |> SelectParam
}

/// Creates a `SelectFragment` off a `Fragment`.
pub fn fragment(fragment frgmt: Fragment) -> SelectValue {
  frgmt |> SelectFragment
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
pub fn all(select slct: Select) -> Select {
  Select(..slct, kind: SelectAll)
}

/// Sets the kind of the `Select` query to
/// return distinct rows only.
///
pub fn distinct(select slct: Select) -> Select {
  Select(..slct, kind: SelectDistinct)
}

/// Gets the kind of the `Select` query.
///
pub fn get_kind(select slct: Select, kind knd: SelectKind) -> Select {
  Select(..slct, kind: knd)
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Select` query to a table name.
///
pub fn from_table(select slct: Select, name tbl_nm: String) -> Select {
  Select(..slct, from: tbl_nm |> FromTable)
}

/// Sets the `FROM` clause of the `Select` query to an aliased sub-query.
///
pub fn from_query(
  select slct: Select,
  sub_query sb_qry: ReadQuery,
  alias als: String,
) -> Select {
  Select(..slct, from: sb_qry |> FromSubQuery(alias: als))
}

/// Removes the `FROM` clause of the `Select` query.
///
pub fn no_from(select slct: Select) -> Select {
  Select(..slct, from: NoFrom)
}

/// Gets the `FROM` clause of the `Select` query.
///
pub fn get_from(select slct: Select) -> From {
  slct.from
}

// ▒▒▒ SELECT ▒▒▒

/// Add a `SelectValue` to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select(select slct: Select, select_value sv: SelectValue) -> Select {
  case slct.select {
    NoSelects -> Select(..slct, select: [sv] |> Selects)
    Selects(slct_slcts) ->
      Select(..slct, select: slct_slcts |> list.append([sv]) |> Selects)
  }
}

/// Add a `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select(
  select slct: Select,
  select_value sv: SelectValue,
) -> Select {
  case slct.select {
    NoSelects -> Select(..slct, select: [sv] |> Selects)
    Selects(slct_slcts) ->
      Select(..slct, select: slct_slcts |> list.append([sv]) |> Selects)
  }
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn selects(
  select slct: Select,
  select_values svs: List(SelectValue),
) -> Select {
  case svs, slct.select {
    [], _ -> slct
    svs, NoSelects -> Select(..slct, select: svs |> Selects)
    svs, Selects(slct_slcts) ->
      Select(..slct, select: slct_slcts |> list.append(svs) |> Selects)
  }
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_selects(
  select slct: Select,
  select_values svs: List(SelectValue),
) -> Select {
  case svs, slct.select {
    [], _ -> slct
    svs, NoSelects -> Select(..slct, select: svs |> Selects)
    svs, Selects(slct_slcts) ->
      Select(..slct, select: slct_slcts |> list.append(svs) |> Selects)
  }
}

/// Gets the `SelectValue`s of the `Select` query.
///
pub fn get_select(select slct: Select) -> Selects {
  slct.select
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Select` query.
///
pub fn join(select slct: Select, join jn: Join) -> Select {
  case slct.join {
    Joins(jns) -> Select(..slct, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Select(..slct, join: [jn] |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with a signle `Join`.
///
pub fn replace_join(select slct: Select, join jn: Join) -> Select {
  Select(..slct, join: [jn] |> Joins)
}

/// Adds `Join`s to the `Select` query.
///
pub fn joins(select slct: Select, joins jns: List(Join)) -> Select {
  case jns, slct.join {
    [], _ -> Select(..slct, join: jns |> Joins)
    jns, Joins(slct_joins) ->
      Select(..slct, join: slct_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Select(..slct, join: jns |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with the given `Join`s.
///
pub fn replace_joins(select slct: Select, joins jns: List(Join)) -> Select {
  Select(..slct, join: jns |> Joins)
}

/// Removes any `Joins` from the `Select` query.
///
pub fn no_join(select slct: Select) -> Select {
  Select(..slct, join: NoJoins)
}

/// Gets the `Joins` of the `Select` query.
///
pub fn get_joins(select slct: Select) -> Joins {
  slct.join
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
pub fn where(select slct: Select, where whr: Where) -> Select {
  case slct.where {
    NoWhere -> Select(..slct, where: whr)
    AndWhere(wheres) ->
      Select(..slct, where: wheres |> list.append([whr]) |> AndWhere)
    _ -> Select(..slct, where: [slct.where, whr] |> AndWhere)
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
pub fn or_where(select slct: Select, where whr: Where) -> Select {
  case slct.where {
    NoWhere -> Select(..slct, where: whr)
    OrWhere(wheres) ->
      Select(..slct, where: wheres |> list.append([whr]) |> OrWhere)
    _ -> Select(..slct, where: [slct.where, whr] |> OrWhere)
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
pub fn xor_where(select slct: Select, where whr: Where) -> Select {
  case slct.where {
    NoWhere -> Select(..slct, where: whr)
    XorWhere(wheres) ->
      Select(..slct, where: wheres |> list.append([whr]) |> XorWhere)
    _ -> Select(..slct, where: [slct.where, whr] |> XorWhere)
  }
}

/// Replaces the `Where` in the `Select` query.
///
pub fn replace_where(select slct: Select, where whr: Where) -> Select {
  Select(..slct, where: whr)
}

/// Removes the `Where` from the `Select` query.
///
pub fn no_where(select slct: Select) -> Select {
  Select(..slct, where: NoWhere)
}

/// Gets the `Where` of the `Select` query.
///
pub fn get_where(select slct: Select) -> Where {
  slct.where
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
pub fn having(select slct: Select, having whr: Where) -> Select {
  case slct.having {
    NoWhere -> Select(..slct, having: whr)
    AndWhere(wheres) ->
      Select(..slct, having: wheres |> list.append([whr]) |> AndWhere)
    _ -> Select(..slct, having: [slct.having, whr] |> AndWhere)
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
pub fn or_having(select slct: Select, having whr: Where) -> Select {
  case slct.having {
    NoWhere -> Select(..slct, having: whr)
    OrWhere(wheres) ->
      Select(..slct, having: wheres |> list.append([whr]) |> OrWhere)
    _ -> Select(..slct, having: [slct.having, whr] |> OrWhere)
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
pub fn xor_having(select slct: Select, having whr: Where) -> Select {
  case slct.having {
    NoWhere -> Select(..slct, having: whr)
    XorWhere(wheres) ->
      Select(..slct, having: wheres |> list.append([whr]) |> XorWhere)
    _ -> Select(..slct, having: [slct.having, whr] |> XorWhere)
  }
}

/// Replaces `HAVING` in the `Select` query.
///
/// See function `having` on details why this takes a `Where`.
///
pub fn replace_having(select slct: Select, having whr: Where) -> Select {
  Select(..slct, having: whr)
}

/// Removes `HAVING` from the `Select` query.
///
pub fn no_having(select slct: Select) -> Select {
  Select(..slct, having: NoWhere)
}

/// Gets`HAVING` in the `Select` query.
///
/// See function `having` on details why this returns a `Where`.
///
pub fn get_having(select slct: Select) -> Where {
  slct.having
}

// ▒▒▒ GROUP BY ▒▒▒

/// Sets or appends `GroupBy` a single into an existing `GroupBy`.
///
pub fn group_by(select slct: Select, group_by grpb: String) -> Select {
  case slct.group_by {
    NoGroupBy -> Select(..slct, group_by: [grpb] |> GroupBy)
    GroupBy(grpbs) ->
      Select(..slct, group_by: grpbs |> list.append([grpb]) |> GroupBy)
  }
}

/// Replaces `GroupBy` with a single `GroupBy`.
///
pub fn replace_group_by(select slct: Select, group_by grpb: String) -> Select {
  Select(..slct, group_by: [grpb] |> GroupBy)
}

/// Sets or appends a list of `GroupBy` into an existing `GroupBy`.
///
pub fn group_bys(select slct: Select, group_bys grpbs: List(String)) -> Select {
  case slct.group_by {
    NoGroupBy -> Select(..slct, group_by: grpbs |> GroupBy)
    GroupBy(grpbs) ->
      Select(..slct, group_by: grpbs |> list.append(grpbs) |> GroupBy)
  }
}

/// Replaces `GroupBy` with a list of `GroupBy`s.
///
pub fn replace_group_bys(
  select slct: Select,
  group_bys grpbs: List(String),
) -> Select {
  Select(..slct, group_by: grpbs |> GroupBy)
}

/// Removes `GroupBy` from the `Select` query.
///
pub fn no_group_by(select slct: Select) -> Select {
  Select(..slct, group_by: NoGroupBy)
}

/// Gets `GroupBy` in the `Select` query.
///
pub fn get_group_by(select slct: Select) -> GroupBy {
  slct.group_by
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Select` query.
///
pub fn limit(select slct: Select, limit lmt: Int) -> Select {
  let lmt = lmt |> read_query.limit_new
  Select(..slct, limit: lmt)
}

/// Removes `Limit` from the `Select` query.
///
pub fn no_limit(select slct: Select) -> Select {
  Select(..slct, limit: NoLimit)
}

/// Gets `Limit` in the `Select` query.
///
pub fn get_limit(select slct: Select) -> Limit {
  slct.limit
}

/// Sets an `Offset` in the `Select` query.
///
pub fn offset(select slct: Select, offst offst: Int) -> Select {
  let offst = offst |> read_query.offset_new
  Select(..slct, offset: offst)
}

/// Removes `Offset` from the `Select` query.
///
pub fn no_offset(select slct: Select) -> Select {
  Select(..slct, offset: NoOffset)
}

/// Gets `Offset` in the `Select` query.
///
pub fn get_offset(select slct: Select) -> Offset {
  slct.offset
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
pub fn order_by_asc(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.Asc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_asc_nulls_first(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.AscNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.AscNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.Asc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_asc_nulls_first(
  select slct: Select,
  by ordb: String,
) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.AscNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_asc_nulls_last(
  select slct: Select,
  by ordb: String,
) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.AscNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_desc_nulls_first(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.DescNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_desc_nulls_last(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.DescNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single descending order.
///
pub fn replace_order_by_desc(select slct: Select, by ordb: String) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_desc_nulls_first(
  select slct: Select,
  by ordb: String,
) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.DescNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_desc_nulls_last(
  select slct: Select,
  by ordb: String,
) -> Select {
  slct
  |> read_query.select_order_by(
    by: [ordb |> OrderByColumn(direction: read_query.DescNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Creates or appends an `OrderBy` a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  select slct: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  slct
  |> read_query.select_order_by([ordb |> OrderByColumn(dir)] |> OrderBy, True)
}

/// Replaces the `OrderBy` a column with a direction.
///
pub fn replace_order_by(
  select slct: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  slct
  |> read_query.select_order_by([ordb |> OrderByColumn(dir)] |> OrderBy, False)
}

/// Removes the `OrderBy` from the `Select` query.
///
pub fn no_order_by(select slct: Select) -> Select {
  Select(..slct, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Select` query.
///
pub fn get_order_by(select slct: Select) -> OrderBy {
  slct.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Select` query.
///
pub fn epilog(select slct: Select, epilog eplg: String) -> Select {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Select(..slct, epilog: NoEpilog)
    _ -> Select(..slct, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Select` query.
///
pub fn no_epilog(select slct: Select) -> Select {
  Select(..slct, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Select` query.
///
pub fn get_epilog(select slct: Select) -> Epilog {
  slct.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Select` query.
///
pub fn comment(select slct: Select, comment cmmnt: String) -> Select {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Select(..slct, comment: NoComment)
    _ -> Select(..slct, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Removes the `Comment` from the `Select` query.
///
pub fn no_comment(select slct: Select) -> Select {
  Select(..slct, comment: NoComment)
}

/// Gets the `Comment` from the `Select` query.
///
pub fn get_comment(select slct: Select) -> Comment {
  slct.comment
}
