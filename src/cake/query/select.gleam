import cake/internal/query.{
  type Fragment, type FromPart, type Join, type LimitOffsetPart,
  type OrderByDirectionPart, type Query, type SelectQuery, type SelectValue,
  type WherePart, NoEpilogPart, NoFromPart, NoLimitNoOffset, NoWherePart,
  OrderByColumnPart, Select, SelectQuery,
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

pub fn new(from frm: FromPart, select slct: List(SelectValue)) -> SelectQuery {
  SelectQuery(
    select: slct,
    from: frm,
    where: NoWherePart,
    joins: [],
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilogPart,
  )
}

pub fn new_from(from frm: FromPart) -> SelectQuery {
  SelectQuery(
    select: [],
    from: frm,
    joins: [],
    where: NoWherePart,
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilogPart,
  )
}

pub fn new_select(select slct: List(SelectValue)) -> SelectQuery {
  SelectQuery(
    select: slct,
    from: NoFromPart,
    where: NoWherePart,
    joins: [],
    order_by: [],
    limit_offset: NoLimitNoOffset,
    epilog: NoEpilogPart,
  )
}

// ▒▒▒ FROM ▒▒▒

pub fn set_from(
  select_query qry: SelectQuery,
  from frm: FromPart,
) -> SelectQuery {
  SelectQuery(..qry, from: frm)
}

pub fn get_from(select_query qry: SelectQuery) -> FromPart {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn select(
  select_query qry: SelectQuery,
  select_parts prts: List(SelectValue),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, prts))
}

pub fn select_replace(
  select_query qry: SelectQuery,
  select_parts prts: List(SelectValue),
) -> SelectQuery {
  SelectQuery(..qry, select: prts)
}

pub fn get_select(select_query qry: SelectQuery) -> List(SelectValue) {
  qry.select
}

// ▒▒▒ WHERE ▒▒▒

pub fn where(select_query qry: SelectQuery, where whr: WherePart) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

pub fn or_where(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  let new_where = query.OrWhere([qry.where, whr])
  SelectQuery(..qry, where: new_where)
}

// TODO
// pub fn xor_where(
//   select_query qry: SelectQuery,
//   where whr: WherePart,
// ) -> SelectQuery {
//   let new_where = query.XorWhere([qry.where, whr])
//   SelectQuery(..qry, where: new_where)
// }

pub fn where_replace(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

pub fn get_where(select_query qry: SelectQuery) -> WherePart {
  qry.where
}

// ▒▒▒ JOIN ▒▒▒

pub fn join(select_query qry: SelectQuery, join_part prt: Join) -> SelectQuery {
  SelectQuery(..qry, joins: list.append(qry.joins, [prt]))
}

pub fn join_replace(
  select_query qry: SelectQuery,
  join_part prt: Join,
) -> SelectQuery {
  SelectQuery(..qry, joins: [prt])
}

pub fn joins(
  select_query qry: SelectQuery,
  join_parts prts: List(Join),
) -> SelectQuery {
  SelectQuery(..qry, joins: list.append(qry.joins, prts))
}

pub fn joins_replace(
  select_query qry: SelectQuery,
  join_parts prts: List(Join),
) -> SelectQuery {
  SelectQuery(..qry, joins: prts)
}

pub fn get_joins(select_query qry: SelectQuery) -> List(Join) {
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

pub fn get_limit_and_offset(select_query qry: SelectQuery) -> LimitOffsetPart {
  qry.limit_offset
}

// ▒▒▒ ORDER BY ▒▒▒

pub type SelectOrderByDirectionPart {
  Asc
  Desc
}

fn map_order_by_direction_part_constructor(
  in: SelectOrderByDirectionPart,
) -> OrderByDirectionPart {
  case in {
    Asc -> query.Asc
    Desc -> query.Desc
  }
}

pub fn order_asc(select_query qry: SelectQuery, by ordb: String) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumnPart(ordb, query.Asc), True)
}

pub fn order_asc_nulls_first(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumnPart(ordb, query.AscNullsFirst), True)
}

pub fn order_asc_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumnPart(ordb, query.Asc), False)
}

pub fn order_asc_nulls_first_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumnPart(ordb, query.AscNullsFirst), False)
}

pub fn order_desc(select_query qry: SelectQuery, by ordb: String) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumnPart(ordb, query.Desc), True)
}

pub fn order_desc_nulls_first(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumnPart(ordb, query.DescNullsFirst), True)
}

pub fn order_desc_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry |> query.select_order_by(OrderByColumnPart(ordb, query.Desc), False)
}

pub fn order_desc_nulls_first_replace(
  select_query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  qry
  |> query.select_order_by(OrderByColumnPart(ordb, query.DescNullsFirst), False)
}

pub fn order(
  select_query qry: SelectQuery,
  by ordb: String,
  direction dir: SelectOrderByDirectionPart,
) -> SelectQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.select_order_by(OrderByColumnPart(ordb, dir), True)
}

pub fn order_replace(
  select_query qry: SelectQuery,
  by ordb: String,
  direction dir: SelectOrderByDirectionPart,
) -> SelectQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.select_order_by(OrderByColumnPart(ordb, dir), False)
}
