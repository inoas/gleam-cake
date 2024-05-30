import cake/internal/query.{
  type Fragment, type From, type Join, type Joins, type LimitOffset,
  type OrderByDirection, type Query, type Select, type SelectValue, type Selects,
  type Where, GroupBy, Joins, NoEpilog, NoFrom, NoGroupBy, NoJoins,
  NoLimitNoOffset, NoOrderBy, NoSelects, NoWhere, OrderBy, OrderByColumn, Select,
  SelectQuery, Selects,
}
import cake/param
import gleam/list

pub fn to_query(query qry: Select) -> Query {
  qry |> SelectQuery
}

pub fn col(name: String) -> SelectValue {
  name |> query.SelectColumn
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

pub fn alias(value v: SelectValue, alias als: String) -> SelectValue {
  v |> query.SelectAlias(alias: als)
}

// ▒▒▒ NEW ▒▒▒

pub fn new(from frm: From, selects slcts: List(SelectValue)) -> Select {
  let slcts = case slcts {
    [] -> NoSelects
    _ -> slcts |> Selects
  }
  Select(
    selects: slcts,
    from: frm,
    joins: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

pub fn new_from(from frm: From) -> Select {
  Select(
    selects: NoSelects,
    from: frm,
    joins: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

pub fn new_select(selects slcts: List(SelectValue)) -> Select {
  let slcts = case slcts {
    [] -> NoSelects
    _ -> slcts |> Selects
  }
  Select(
    selects: slcts,
    from: NoFrom,
    joins: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

// ▒▒▒ FROM ▒▒▒

pub fn set_from(query qry: Select, from frm: From) -> Select {
  Select(..qry, from: frm)
}

pub fn get_from(query qry: Select) -> From {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn selects(query qry: Select, select_values sv: List(SelectValue)) -> Select {
  case sv, qry.selects {
    [], _ -> qry
    sv, NoSelects -> Select(..qry, selects: Selects(sv))
    sv, Selects(qry_slcts) ->
      Select(..qry, selects: qry_slcts |> list.append(sv) |> Selects)
  }
}

pub fn selects_replace(
  query qry: Select,
  select_values sv: List(SelectValue),
) -> Select {
  case sv, qry.selects {
    [], _ -> qry
    sv, NoSelects -> Select(..qry, selects: Selects(sv))
    sv, Selects(qry_slcts) ->
      Select(..qry, selects: qry_slcts |> list.append(sv) |> Selects)
  }
}

pub fn get_selects(query qry: Select) -> Selects {
  qry.selects
}

// ▒▒▒ JOIN ▒▒▒

pub fn join(query qry: Select, join_part prt: Join) -> Select {
  case qry.joins {
    Joins(prts) -> Select(..qry, joins: prts |> list.append([prt]) |> Joins)
    NoJoins -> Select(..qry, joins: [prt] |> Joins)
  }
}

pub fn join_replace(query qry: Select, join_part prt: Join) -> Select {
  Select(..qry, joins: [prt] |> Joins)
}

pub fn joins(query qry: Select, joins jns: List(Join)) -> Select {
  case jns, qry.joins {
    [], _ -> Select(..qry, joins: Joins(jns))
    jns, Joins(qry_joins) ->
      Select(..qry, joins: qry_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Select(..qry, joins: jns |> Joins)
  }
}

pub fn joins_replace(query qry: Select, join_parts prts: List(Join)) -> Select {
  Select(..qry, joins: prts |> Joins)
}

pub fn joins_remove(query qry: Select) -> Select {
  Select(..qry, joins: NoJoins)
}

pub fn get_joins(query qry: Select) -> Joins {
  qry.joins
}

// ▒▒▒ WHERE ▒▒▒

pub fn where(query qry: Select, where whr: Where) -> Select {
  Select(..qry, where: whr)
}

pub fn or_where(query qry: Select, where whr: Where) -> Select {
  let new_where = query.OrWhere([qry.where, whr])
  Select(..qry, where: new_where)
}

// TODO
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

pub fn set_limit_and_offset(
  query qry: Select,
  limit lmt: Int,
  offset offst: Int,
) -> Select {
  let lmt_offst = query.limit_offset_new(limit: lmt, offset: offst)
  Select(..qry, limit_offset: lmt_offst)
}

pub fn set_limit(query qry: Select, limit lmt: Int) -> Select {
  let lmt_offst = query.limit_new(lmt)
  Select(..qry, limit_offset: lmt_offst)
}

pub fn set_offset(query qry: Select, limit lmt: Int) -> Select {
  let lmt_offst = query.offset_new(lmt)
  Select(..qry, limit_offset: lmt_offst)
}

pub fn get_limit_and_offset(query qry: Select) -> LimitOffset {
  qry.limit_offset
}

// ▒▒▒ ORDER BY ▒▒▒

pub type SelectOrderByDirection {
  Asc
  Desc
}

fn map_order_by_direction_part_constructor(
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
  let dir = dir |> map_order_by_direction_part_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

pub fn order_replace(
  query qry: Select,
  by ordb: String,
  direction dir: SelectOrderByDirection,
) -> Select {
  let dir = dir |> map_order_by_direction_part_constructor
  qry
  |> query.select_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}
