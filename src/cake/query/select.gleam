//// A DSL to build `SELECT` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type Fragment, type From, type GroupBy, type Join,
  type Joins, type Limit, type Offset, type OrderBy, type OrderByDirection,
  type Query, type Select, type SelectKind, type SelectValue, type Selects,
  type Where, AndWhere, Comment, Epilog, FromSubQuery, FromTable, GroupBy, Joins,
  Limit, NoComment, NoEpilog, NoFrom, NoGroupBy, NoJoins, NoLimit, NoOffset,
  NoOrderBy, NoSelects, NoWhere, Offset, OrWhere, OrderBy, OrderByColumn, Select,
  SelectAlias, SelectAll, SelectColumn, SelectDistinct, SelectFragment,
  SelectParam, SelectQuery, Selects, XorWhere,
}
import cake/param
import gleam/list
import gleam/string

/// Creates a `Query` from a `Select` query.
///
pub fn to_query(query qry: Select) -> Query {
  qry |> SelectQuery
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
  vl |> param.bool |> SelectParam
}

/// Creates a float `Param` off a `Float`.
///
pub fn float(value vl: Float) -> SelectValue {
  vl |> param.float |> SelectParam
}

/// Creates an integer `Param` off an `Int`.
///
pub fn int(value vl: Int) -> SelectValue {
  vl |> param.int |> SelectParam
}

/// Creates a string `Param` off a `String`.
///
pub fn string(value vl: String) -> SelectValue {
  vl |> param.string |> SelectParam
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
pub fn all(query qry: Select) -> Select {
  Select(..qry, kind: SelectAll)
}

/// Sets the kind of the `Select` query to
/// return distinct rows only.
///
pub fn distinct(query qry: Select) -> Select {
  Select(..qry, kind: SelectDistinct)
}

/// Gets the kind of the `Select` query.
///
pub fn get_kind(query qry: Select, kind knd: SelectKind) -> Select {
  Select(..qry, kind: knd)
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Select` query to a table name.
///
pub fn from_table(query qry: Select, name tbl_nm: String) -> Select {
  Select(..qry, from: FromTable(name: tbl_nm))
}

/// Sets the `FROM` clause of the `Select` query to an aliased sub-query.
///
pub fn from_sub_query(
  query qry: Select,
  sub_query sb_qry: Query,
  alias als: String,
) -> Select {
  Select(..qry, from: FromSubQuery(sub_query: sb_qry, alias: als))
}

/// Removes the `FROM` clause of the `Select` query.
///
pub fn no_from(query qry: Select) -> Select {
  Select(..qry, from: NoFrom)
}

/// Gets the `FROM` clause of the `Select` query.
///
pub fn get_from(query qry: Select) -> From {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

/// Add a `SelectValue` to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select(query qry: Select, select_value sv: SelectValue) -> Select {
  case qry.select {
    NoSelects -> Select(..qry, select: Selects([sv]))
    Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append([sv]) |> Selects)
  }
}

/// Add a `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select(query qry: Select, select_value sv: SelectValue) -> Select {
  case qry.select {
    NoSelects -> Select(..qry, select: Selects([sv]))
    Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append([sv]) |> Selects)
  }
}

/// Adds `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn selects(
  query qry: Select,
  select_values svs: List(SelectValue),
) -> Select {
  case svs, qry.select {
    [], _ -> qry
    svs, NoSelects -> Select(..qry, select: Selects(svs))
    svs, Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append(svs) |> Selects)
  }
}

/// Adds `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_selects(
  query qry: Select,
  select_values svs: List(SelectValue),
) -> Select {
  case svs, qry.select {
    [], _ -> qry
    svs, NoSelects -> Select(..qry, select: Selects(svs))
    svs, Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append(svs) |> Selects)
  }
}

/// Gets the `SelectValue`s of the `Select` query.
///
pub fn get_select(query qry: Select) -> Selects {
  qry.select
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Select` query.
///
pub fn join(query qry: Select, join jn: Join) -> Select {
  case qry.join {
    Joins(jns) -> Select(..qry, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Select(..qry, join: [jn] |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with a signle `Join`.
///
pub fn replace_join(query qry: Select, join jn: Join) -> Select {
  Select(..qry, join: [jn] |> Joins)
}

/// Adds `Join`s to the `Select` query.
///
pub fn joins(query qry: Select, joins jns: List(Join)) -> Select {
  case jns, qry.join {
    [], _ -> Select(..qry, join: Joins(jns))
    jns, Joins(qry_joins) ->
      Select(..qry, join: qry_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Select(..qry, join: jns |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with the given `Join`s.
///
pub fn replace_joins(query qry: Select, joins jns: List(Join)) -> Select {
  Select(..qry, join: jns |> Joins)
}

/// Removes any `Joins` from the `Select` query.
///
pub fn no_join(query qry: Select) -> Select {
  Select(..qry, join: NoJoins)
}

/// Gets the `Joins` of the `Select` query.
///
pub fn get_joins(query qry: Select) -> Joins {
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
pub fn where(query qry: Select, where whr: Where) -> Select {
  case qry.where {
    NoWhere -> Select(..qry, where: whr)
    AndWhere(wheres) ->
      Select(..qry, where: AndWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, where: AndWhere([qry.where, whr]))
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
pub fn or_where(query qry: Select, where whr: Where) -> Select {
  case qry.where {
    NoWhere -> Select(..qry, where: whr)
    OrWhere(wheres) ->
      Select(..qry, where: OrWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, where: OrWhere([qry.where, whr]))
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
pub fn xor_where(query qry: Select, where whr: Where) -> Select {
  case qry.where {
    NoWhere -> Select(..qry, where: whr)
    XorWhere(wheres) ->
      Select(..qry, where: XorWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, where: XorWhere([qry.where, whr]))
  }
}

/// Replaces the `Where` in the `Select` query.
///
pub fn replace_where(query qry: Select, where whr: Where) -> Select {
  Select(..qry, where: whr)
}

/// Removes the `Where` from the `Select` query.
///
pub fn no_where(query qry: Select) -> Select {
  Select(..qry, where: NoWhere)
}

/// Gets the `Where` of the `Select` query.
///
pub fn get_where(query qry: Select) -> Where {
  qry.where
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
/// NOTICE: `HAVING` allows to specify constraints much like `WHERE`,
///         but filters the results after `GROUP BY` is applied instead of
///         before. Because `HAVING` uses the same semantics as `WHERE`, it
///         takes a `Where`.
///
pub fn having(query qry: Select, having whr: Where) -> Select {
  case qry.having {
    NoWhere -> Select(..qry, having: whr)
    AndWhere(wheres) ->
      Select(..qry, having: AndWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, having: AndWhere([qry.having, whr]))
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
pub fn or_having(query qry: Select, having whr: Where) -> Select {
  case qry.having {
    NoWhere -> Select(..qry, having: whr)
    OrWhere(wheres) ->
      Select(..qry, having: OrWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, having: OrWhere([qry.having, whr]))
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
/// NOTICE: This operator does not exist in Postgres or Sqlite,
///         and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
///         This operator exists in MariaDB/MySQL.
///
pub fn xor_having(query qry: Select, having whr: Where) -> Select {
  case qry.having {
    NoWhere -> Select(..qry, having: whr)
    XorWhere(wheres) ->
      Select(..qry, having: XorWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, having: XorWhere([qry.having, whr]))
  }
}

/// Replaces `HAVING` in the `Select` query.
///
/// See function `having` on details why this takes a `Where`.
///
pub fn replace_having(query qry: Select, having whr: Where) -> Select {
  Select(..qry, having: whr)
}

/// Removes `HAVING` from the `Select` query.
///
pub fn no_having(query qry: Select) -> Select {
  Select(..qry, having: NoWhere)
}

/// Gets`HAVING` in the `Select` query.
///
/// See function `having` on details why this returns a `Where`.
///
pub fn get_having(query qry: Select) -> Where {
  qry.having
}

// ▒▒▒ GROUP BY ▒▒▒

/// Sets or appends `GroupBy` a single into an existing `GroupBy`.
///
pub fn group_by(query qry: Select, group_by grpb: String) -> Select {
  case qry.group_by {
    NoGroupBy -> Select(..qry, group_by: GroupBy([grpb]))
    GroupBy(grpbs) ->
      Select(..qry, group_by: GroupBy(grpbs |> list.append([grpb])))
  }
}

/// Replaces `GroupBy` with a single `GroupBy`.
///
pub fn replace_group_by(query qry: Select, group_by grpb: String) -> Select {
  Select(..qry, group_by: GroupBy([grpb]))
}

/// Sets or appends a list of `GroupBy` into an existing `GroupBy`.
///
pub fn groups_by(query qry: Select, group_bys grpbs: List(String)) -> Select {
  case qry.group_by {
    NoGroupBy -> Select(..qry, group_by: GroupBy(grpbs))
    GroupBy(grpbs) ->
      Select(..qry, group_by: GroupBy(grpbs |> list.append(grpbs)))
  }
}

/// Replaces `GroupBy` with a list of `GroupBy`s.
///
pub fn replace_group_bys(
  query qry: Select,
  group_bys grpbs: List(String),
) -> Select {
  Select(..qry, group_by: GroupBy(grpbs))
}

/// Removes `GroupBy` from the `Select` query.
///
pub fn no_group_by(query qry: Select) -> Select {
  Select(..qry, group_by: NoGroupBy)
}

/// Gets `GroupBy` in the `Select` query.
///
pub fn get_group_by(query qry: Select) -> GroupBy {
  qry.group_by
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Select` query.
///
pub fn limit(query qry: Select, limit lmt: Int) -> Select {
  let lmt = lmt |> query.limit_new
  Select(..qry, limit: lmt)
}

/// Removes `Limit` from the `Select` query.
///
pub fn no_limit(query qry: Select) -> Select {
  Select(..qry, limit: NoLimit)
}

/// Gets `Limit` in the `Select` query.
///
pub fn get_limit(query qry: Select) -> Limit {
  qry.limit
}

/// Sets an `Offset` in the `Select` query.
///
pub fn offset(query qry: Select, offst offst: Int) -> Select {
  let offst = offst |> query.offset_new
  Select(..qry, offset: offst)
}

/// Removes `Offset` from the `Select` query.
///
pub fn no_offset(query qry: Select) -> Select {
  Select(..qry, offset: NoOffset)
}

/// Gets `Offset` in the `Select` query.
///
pub fn get_offset(query qry: Select) -> Offset {
  qry.offset
}

// ▒▒▒ ORDER BY ▒▒▒

/// Defines the direction of an `OrderBy`.
///
pub type Direction {
  Asc
  Desc
}

fn map_order_by_direction_constructor(in: Direction) -> OrderByDirection {
  case in {
    Asc -> query.Asc
    Desc -> query.Desc
  }
}

/// Creates or appends an ascending `OrderBy`.
///
pub fn order_by_asc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_asc_nulls_first(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: True,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_asc_nulls_first(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_asc_nulls_last(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: False,
  )
}

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_desc_nulls_first(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: True,
  )
}

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_desc_nulls_last(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: True,
  )
}

/// Replaces the `OrderBy` a single descending order.
///
pub fn replace_order_by_desc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending order with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_desc_nulls_first(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_desc_nulls_last(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: False,
  )
}

/// Creates or appends an `OrderBy` a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  query qry: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

/// Replaces the `OrderBy` a column with a direction.
///
pub fn replace_order_by(
  query qry: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}

/// Removes the `OrderBy` from the `Select` query.
///
pub fn no_order_by(query qry: Select) -> Select {
  Select(..qry, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Select` query.
///
pub fn get_order_by(query qry: Select) -> OrderBy {
  qry.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Select` query.
///
pub fn epilog(query qry: Select, epilog eplg: String) -> Select {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Select(..qry, epilog: NoEpilog)
    _ -> Select(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Select` query.
///
pub fn no_epilog(query qry: Select) -> Select {
  Select(..qry, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Select` query.
///
pub fn get_epilog(query qry: Select) -> Epilog {
  qry.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Select` query.
///
pub fn comment(query qry: Select, comment cmmnt: String) -> Select {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Select(..qry, comment: NoComment)
    _ -> Select(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Removes the `Comment` from the `Select` query.
///
pub fn no_comment(query qry: Select) -> Select {
  Select(..qry, comment: NoComment)
}

/// Gets the `Comment` from the `Select` query.
///
pub fn get_comment(query qry: Select) -> Comment {
  qry.comment
}
