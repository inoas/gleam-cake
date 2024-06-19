//// A DSL to build `SELECT` queries.
////
//// `HAVING` allows to specify constraints much like `WHERE`,
//// but filters the results after `GROUP BY` is applied
//// instead of before
////

import cake/internal/query.{
  type Comment, type Epilog, type Fragment, type From, type Join, type Joins,
  type Limit, type Offset, type OrderByDirection, type Query, type Select,
  type SelectKind, type SelectValue, type Selects, type Where, AndWhere, Comment,
  Epilog, GroupBy, Joins, Limit, NoComment, NoEpilog, NoFrom, NoGroupBy, NoJoins,
  NoLimit, NoOffset, NoOrderBy, NoSelects, NoWhere, Offset, OrWhere, OrderBy,
  OrderByColumn, Select, SelectAll, SelectDistinct, SelectQuery, Selects,
}
import cake/param
import gleam/list
import gleam/string

pub fn to_query(query qry: Select) -> Query {
  qry |> SelectQuery
}

pub fn col(name: String) -> SelectValue {
  name |> query.SelectColumn
}

pub fn alias(value v: SelectValue, alias als: String) -> SelectValue {
  v |> query.SelectAlias(alias: als)
}

pub fn bool(value: Bool) -> SelectValue {
  value |> param.bool |> query.SelectParam
}

pub fn float(value: Float) -> SelectValue {
  value |> param.float |> query.SelectParam
}

pub fn int(value: Int) -> SelectValue {
  value |> param.int |> query.SelectParam
}

pub fn string(value: String) -> SelectValue {
  value |> param.string |> query.SelectParam
}

pub fn fragment(fragment frgmt: Fragment) -> SelectValue {
  frgmt |> query.SelectFragment
}

// ▒▒▒ NEW ▒▒▒

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

pub fn new_from(from frm: From) -> Select {
  Select(
    kind: SelectAll,
    select: NoSelects,
    from: frm,
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

pub fn all(query qry: Select) -> Select {
  Select(..qry, kind: SelectAll)
}

pub fn distinct(query qry: Select) -> Select {
  Select(..qry, kind: SelectDistinct)
}

pub fn get_kind(query qry: Select, kind knd: SelectKind) -> Select {
  Select(..qry, kind: knd)
}

// ▒▒▒ FROM ▒▒▒

pub fn from(query qry: Select, from frm: From) -> Select {
  Select(..qry, from: frm)
}

pub fn get_from(query qry: Select) -> From {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn select(query qry: Select, select_values sv: List(SelectValue)) -> Select {
  case sv, qry.select {
    [], _ -> qry
    sv, NoSelects -> Select(..qry, select: Selects(sv))
    sv, Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append(sv) |> Selects)
  }
}

pub fn select_replace(
  query qry: Select,
  select_values sv: List(SelectValue),
) -> Select {
  case sv, qry.select {
    [], _ -> qry
    sv, NoSelects -> Select(..qry, select: Selects(sv))
    sv, Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append(sv) |> Selects)
  }
}

pub fn get_select(query qry: Select) -> Selects {
  qry.select
}

// ▒▒▒ JOIN ▒▒▒

pub fn join(query qry: Select, join jn: Join) -> Select {
  case qry.join {
    Joins(jns) -> Select(..qry, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Select(..qry, join: [jn] |> Joins)
  }
}

pub fn join_replace(query qry: Select, join jn: Join) -> Select {
  Select(..qry, join: [jn] |> Joins)
}

pub fn joins(query qry: Select, joins jns: List(Join)) -> Select {
  case jns, qry.join {
    [], _ -> Select(..qry, join: Joins(jns))
    jns, Joins(qry_joins) ->
      Select(..qry, join: qry_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Select(..qry, join: jns |> Joins)
  }
}

pub fn joins_replace(query qry: Select, joins jns: List(Join)) -> Select {
  Select(..qry, join: jns |> Joins)
}

pub fn joins_remove(query qry: Select) -> Select {
  Select(..qry, join: NoJoins)
}

pub fn get_joins(query qry: Select) -> Joins {
  qry.join
}

// ▒▒▒ WHERE ▒▒▒

pub fn where(query qry: Select, where whr: Where) -> Select {
  case qry.where {
    NoWhere -> Select(..qry, where: whr)
    AndWhere(wheres) ->
      Select(..qry, where: AndWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, where: query.AndWhere([qry.where, whr]))
  }
}

pub fn or_where(query qry: Select, where whr: Where) -> Select {
  case qry.where {
    NoWhere -> Select(..qry, where: whr)
    OrWhere(wheres) ->
      Select(..qry, where: OrWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, where: query.OrWhere([qry.where, whr]))
  }
}

pub fn xor_where(query qry: Select, where whr: Where) -> Select {
  let new_where = query.XorWhere([qry.where, whr])
  Select(..qry, where: new_where)
}

pub fn where_replace(query qry: Select, where whr: Where) -> Select {
  Select(..qry, where: whr)
}

pub fn get_where(query qry: Select) -> Where {
  qry.where
}

// ▒▒▒ HAVING ▒▒▒

/// `HAVING` allows to specify constraints much like `WHERE`,
/// but filters the results after `GROUP BY` is applied
/// instead of before.
///
/// Because it uses the same semantics as `WHERE`, it takes a `Where`
///
pub fn having(query qry: Select, having whr: Where) -> Select {
  case qry.having {
    NoWhere -> Select(..qry, having: whr)
    AndWhere(wheres) ->
      Select(..qry, having: AndWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, having: query.AndWhere([qry.having, whr]))
  }
}

/// See `having` on details why this takes a where
///
pub fn or_having(query qry: Select, having whr: Where) -> Select {
  case qry.having {
    NoWhere -> Select(..qry, having: whr)
    OrWhere(wheres) ->
      Select(..qry, having: OrWhere(wheres |> list.append([whr])))
    _ -> Select(..qry, having: query.OrWhere([qry.having, whr]))
  }
}

/// See `having` on details why this takes a where
///
pub fn xor_having(query qry: Select, having whr: Where) -> Select {
  let new_where = query.XorWhere([qry.having, whr])
  Select(..qry, having: new_where)
}

/// See `having` on details why this takes a where
///
pub fn having_replace(query qry: Select, having whr: Where) -> Select {
  Select(..qry, having: whr)
}

/// See `having` on details why returns a where
///
pub fn get_having(query qry: Select) -> Where {
  qry.having
}

// ▒▒▒ GROUP BY ▒▒▒

pub fn group_by(query qry: Select, group_by grpb: String) -> Select {
  case qry.group_by {
    NoGroupBy -> Select(..qry, group_by: GroupBy([grpb]))
    GroupBy(grpbs) ->
      Select(..qry, group_by: GroupBy(grpbs |> list.append([grpb])))
  }
}

pub fn group_by_replace(query qry: Select, group_by grpb: String) -> Select {
  Select(..qry, group_by: GroupBy([grpb]))
}

pub fn groups_by(query qry: Select, group_bys grpbs: List(String)) -> Select {
  case qry.group_by {
    NoGroupBy -> Select(..qry, group_by: GroupBy(grpbs))
    GroupBy(grpbs) ->
      Select(..qry, group_by: GroupBy(grpbs |> list.append(grpbs)))
  }
}

pub fn group_bys_replace(
  query qry: Select,
  group_bys grpbs: List(String),
) -> Select {
  Select(..qry, group_by: GroupBy(grpbs))
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

pub fn limit(query qry: Select, limit lmt: Int) -> Select {
  let lmt = lmt |> query.limit_new
  Select(..qry, limit: lmt)
}

pub fn get_limit(query qry: Select) -> Limit {
  qry.limit
}

pub fn offset(query qry: Select, offst offst: Int) -> Select {
  let offst = offst |> query.offset_new
  Select(..qry, offset: offst)
}

pub fn get_offset(query qry: Select) -> Offset {
  qry.offset
}

// ▒▒▒ ORDER BY ▒▒▒

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

pub fn order_asc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    True,
  )
}

pub fn order_asc_nulls_first(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    True,
  )
}

pub fn order_asc_replace(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    False,
  )
}

pub fn order_asc_nulls_first_replace(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    False,
  )
}

pub fn order_desc(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    True,
  )
}

pub fn order_desc_nulls_first(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    True,
  )
}

pub fn order_desc_replace(query qry: Select, by ordb: String) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    False,
  )
}

pub fn order_desc_nulls_first_replace(
  query qry: Select,
  by ordb: String,
) -> Select {
  qry
  |> query.select_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    False,
  )
}

pub fn order(
  query qry: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

pub fn order_replace(
  query qry: Select,
  by ordb: String,
  direction dir: Direction,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}

// ▒▒▒ EPILOG ▒▒▒

pub fn epilog(query qry: Select, epilog eplg: String) -> Select {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Select(..qry, epilog: NoEpilog)
    _ -> Select(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn epilog_remove(query qry: Select) -> Select {
  Select(..qry, epilog: NoEpilog)
}

pub fn get_epilog(query qry: Select) -> Epilog {
  qry.epilog
}

// ▒▒▒ COMMENT ▒▒▒

pub fn comment(query qry: Select, comment cmmnt: String) -> Select {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Select(..qry, comment: NoComment)
    _ -> Select(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

pub fn comment_remove(query qry: Select) -> Select {
  Select(..qry, comment: NoComment)
}

pub fn get_comment(query qry: Select) -> Comment {
  qry.comment
}
// TODO v3:
// pub fn col_exists(connection conn: Connection, table_name tbl_nm: String, column col: String) -> Boolean {
//   todo
// }

// TODO v3:
// pub fn cols_exist(connection conn: Connection, table_name tbl_nm: String, columns cols: List(String)) -> List(#(String, Boolean)) {
//   todo
// }
