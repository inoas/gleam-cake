// TODO v1 module doc
// TODO v1 tests

import cake/internal/query.{
  type Fragment, type From, type Join, type Joins, type Limit, type Offset,
  type OrderByDirection, type Query, type Select, type SelectKind,
  type SelectValue, type Selects, type Where, AndWhere, GroupBy, Joins, Limit,
  NoEpilog, NoFrom, NoGroupBy, NoJoins, NoLimit, NoOffset, NoOrderBy, NoSelects,
  NoWhere, Offset, OrWhere, OrderBy, OrderByColumn, Select, SelectAll,
  SelectDistinct, SelectQuery, Selects,
}
import cake/param
import gleam/list

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

pub fn from(from frm: From) -> Select {
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
  )
}

pub fn from_distinct(from frm: From) -> Select {
  Select(
    kind: SelectDistinct,
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
  )
}

pub fn select(selects slcts: List(SelectValue)) -> Select {
  case slcts {
    [] -> NoSelects
    _ -> slcts |> Selects
  }
  |> Select(
    kind: SelectAll,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit: NoLimit,
    offset: NoOffset,
    epilog: NoEpilog,
  )
}

pub fn distinct(selects slcts: List(SelectValue)) -> Select {
  case slcts {
    [] -> NoSelects
    _ -> slcts |> Selects
  }
  |> Select(
    kind: SelectDistinct,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit: NoLimit,
    offset: NoOffset,
    epilog: NoEpilog,
  )
}

pub fn kind(query qry: Select, kind knd: SelectKind) -> Select {
  Select(..qry, kind: knd)
}

// ▒▒▒ FROM ▒▒▒

pub fn replace_from(query qry: Select, from frm: From) -> Select {
  Select(..qry, from: frm)
}

pub fn get_from(query qry: Select) -> From {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn selects(query qry: Select, select_values sv: List(SelectValue)) -> Select {
  case sv, qry.select {
    [], _ -> qry
    sv, NoSelects -> Select(..qry, select: Selects(sv))
    sv, Selects(qry_slcts) ->
      Select(..qry, select: qry_slcts |> list.append(sv) |> Selects)
  }
}

pub fn selects_replace(
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

pub fn get_selects(query qry: Select) -> Selects {
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

// TODO v1
// pub fn xor_where(
//   query qry: Select,
//   where whr: Where,
// ) -> Select {
//   let new_where = query.XorWhere([qry.where, whr])
//   Select(..qry, where: new_where)
// }

pub fn where_replace(query qry: Select, where whr: Where) -> Select {
  Select(..qry, where: whr)
}

pub fn get_where(query qry: Select) -> Where {
  qry.where
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

pub type SelectOrderByDirection {
  Asc
  Desc
}

fn map_order_by_direction_constructor(
  in: SelectOrderByDirection,
) -> OrderByDirection {
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
  direction dir: SelectOrderByDirection,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

pub fn order_replace(
  query qry: Select,
  by ordb: String,
  direction dir: SelectOrderByDirection,
) -> Select {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}
