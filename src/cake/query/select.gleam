import cake/internal/query.{
  type Fragment, type From, type Join, type Joins, type LimitOffset,
  type OrderByDirection, type Query, type SelectQuery, type SelectValue,
  type Selects, type Where, Joins, NoEpilog, NoFrom, NoJoins, NoLimitNoOffset,
  NoSelects, NoWhere, OrderByColumn, Select, SelectQuery, Selects,
}
import cake/param
import gleam/list

pub fn to_query(select_query qry: SelectQuery) -> Query {
  qry |> Select
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

pub fn new(from frm: From, selects slcts: List(SelectValue)) -> SelectQuery {
  let slcts = case slcts {
    [] -> NoSelects
    _ -> Selects(slcts)
  }
  SelectQuery(
    selects: slcts,
    from: frm,
    where: NoWhere,
    joins: NoJoins,
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

pub fn new_from(from frm: From) -> SelectQuery {
  SelectQuery(
    selects: NoSelects,
    from: frm,
    joins: NoJoins,
    where: NoWhere,
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

pub fn new_select(selects slcts: List(SelectValue)) -> SelectQuery {
  let slcts = case slcts {
    [] -> NoSelects
    _ -> Selects(slcts)
  }
  SelectQuery(
    selects: slcts,
    from: NoFrom,
    where: NoWhere,
    joins: NoJoins,
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilog,
  )
}

// ▒▒▒ FROM ▒▒▒

pub fn set_from(select_query qry: SelectQuery, from frm: From) -> SelectQuery {
  SelectQuery(..qry, from: frm)
}

pub fn get_from(select_query qry: SelectQuery) -> From {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn selects(
  select_query qry: SelectQuery,
  select_values sv: List(SelectValue),
) -> SelectQuery {
  case sv, qry.selects {
    [], _ -> qry
    sv, NoSelects -> SelectQuery(..qry, selects: Selects(sv))
    sv, Selects(qry_slcts) ->
      SelectQuery(..qry, selects: Selects(qry_slcts |> list.append(sv)))
  }
}

pub fn selects_replace(
  select_query qry: SelectQuery,
  select_values sv: List(SelectValue),
) -> SelectQuery {
  case sv, qry.selects {
    [], _ -> qry
    sv, NoSelects -> SelectQuery(..qry, selects: Selects(sv))
    sv, Selects(qry_slcts) ->
      SelectQuery(..qry, selects: Selects(qry_slcts |> list.append(sv)))
  }
}

pub fn get_selects(select_query qry: SelectQuery) -> Selects {
  qry.selects
}

// ▒▒▒ WHERE ▒▒▒

pub fn where(select_query qry: SelectQuery, where whr: Where) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

pub fn or_where(select_query qry: SelectQuery, where whr: Where) -> SelectQuery {
  let new_where = query.OrWhere([qry.where, whr])
  SelectQuery(..qry, where: new_where)
}

// TODO
// pub fn xor_where(
//   select_query qry: SelectQuery,
//   where whr: Where,
// ) -> SelectQuery {
//   let new_where = query.XorWhere([qry.where, whr])
//   SelectQuery(..qry, where: new_where)
// }

pub fn where_replace(
  select_query qry: SelectQuery,
  where whr: Where,
) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

pub fn get_where(select_query qry: SelectQuery) -> Where {
  qry.where
}

// ▒▒▒ JOIN ▒▒▒

pub fn join(select_query qry: SelectQuery, join_part prt: Join) -> SelectQuery {
  case qry.joins {
    Joins(prts) -> SelectQuery(..qry, joins: Joins(prts |> list.append([prt])))
    NoJoins -> SelectQuery(..qry, joins: Joins([prt]))
  }
}

pub fn join_replace(
  select_query qry: SelectQuery,
  join_part prt: Join,
) -> SelectQuery {
  SelectQuery(..qry, joins: Joins([prt]))
}

pub fn joins(
  select_query qry: SelectQuery,
  joins jns: List(Join),
) -> SelectQuery {
  case jns, qry.joins {
    [], _ -> SelectQuery(..qry, joins: Joins(jns))
    jns, Joins(qry_joins) ->
      SelectQuery(..qry, joins: Joins(qry_joins |> list.append(jns)))
    jns, NoJoins -> SelectQuery(..qry, joins: Joins(jns))
  }
}

pub fn joins_replace(
  select_query qry: SelectQuery,
  join_parts prts: List(Join),
) -> SelectQuery {
  SelectQuery(..qry, joins: Joins(prts))
}

pub fn joins_remove(select_query qry: SelectQuery) -> SelectQuery {
  SelectQuery(..qry, joins: NoJoins)
}

pub fn get_joins(select_query qry: SelectQuery) -> Joins {
  qry.joins
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

pub fn set_limit_and_offset(
  query qry: SelectQuery,
  limit lmt: Int,
  offset offst: Int,
) -> SelectQuery {
  let lmt_offst = query.limit_offset_new(limit: lmt, offset: offst)
  SelectQuery(..qry, limit_offset: lmt_offst)
}

pub fn set_limit(select_query qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  let lmt_offst = query.limit_new(lmt)
  SelectQuery(..qry, limit_offset: lmt_offst)
}

pub fn set_offset(select_query qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  let lmt_offst = query.offset_new(lmt)
  SelectQuery(..qry, limit_offset: lmt_offst)
}

pub fn get_limit_and_offset(select_query qry: SelectQuery) -> LimitOffset {
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

pub fn order_asc(select_query qry: SelectQuery, by ordb: String) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumn(ordb, query.Asc), True)
}

pub fn order_asc_nulls_first(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumn(ordb, query.AscNullsFirst), True)
}

pub fn order_asc_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumn(ordb, query.Asc), False)
}

pub fn order_asc_nulls_first_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumn(ordb, query.AscNullsFirst), False)
}

pub fn order_desc(select_query qry: SelectQuery, by ordb: String) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumn(ordb, query.Desc), True)
}

pub fn order_desc_nulls_first(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumn(ordb, query.DescNullsFirst), True)
}

pub fn order_desc_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumn(ordb, query.Desc), False)
}

pub fn order_desc_nulls_first_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumn(ordb, query.DescNullsFirst), False)
}

pub fn order(
  select_query qry: SelectQuery,
  by ordb: String,
  direction dir: SelectOrderByDirection,
) -> SelectQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.select_order_by(OrderByColumn(ordb, dir), True)
}

pub fn order_replace(
  select_query qry: SelectQuery,
  by ordb: String,
  direction dir: SelectOrderByDirection,
) -> SelectQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.select_order_by(OrderByColumn(ordb, dir), False)
}
