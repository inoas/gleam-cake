// TODO v1 module doc

import cake/internal/query.{
  type Combined, type Limit, type Offset, type OrderByDirection, type Query,
  type Select, Combined, CombinedQuery, Except, ExceptAll, Intersect,
  IntersectAll, OrderBy, OrderByColumn, Union, UnionAll,
}

pub fn to_query(combined_query qry: Combined) -> Query {
  qry |> CombinedQuery
}

// ▒▒▒ Combined Kind ▒▒▒

pub fn union(select_queries qrys: List(Select)) -> Combined {
  Union |> query.combined_query_new(qrys)
}

pub fn union_all(select_queries qrys: List(Select)) -> Combined {
  UnionAll |> query.combined_query_new(qrys)
}

pub fn except(select_queries qrys: List(Select)) -> Combined {
  Except |> query.combined_query_new(qrys)
}

pub fn except_all(select_queries qrys: List(Select)) -> Combined {
  ExceptAll |> query.combined_query_new(qrys)
}

pub fn intersect(select_queries qrys: List(Select)) -> Combined {
  Intersect |> query.combined_query_new(qrys)
}

pub fn intersect_all(select_queries qrys: List(Select)) -> Combined {
  IntersectAll |> query.combined_query_new(qrys)
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

pub fn limit(query qry: Combined, limit lmt: Int) -> Combined {
  let lmt = lmt |> query.limit_new
  Combined(..qry, limit: lmt)
}

pub fn get_limit(query qry: Combined) -> Limit {
  qry.limit
}

pub fn offset(query qry: Combined, offst offst: Int) -> Combined {
  let offst = offst |> query.offset_new
  Combined(..qry, offset: offst)
}

pub fn get_offset(query qry: Combined) -> Offset {
  qry.offset
}

// ▒▒▒ ORDER BY ▒▒▒

pub type CombinedQueryOrderByDirection {
  Asc
  Desc
}

fn map_order_by_direction_constructor(
  in: CombinedQueryOrderByDirection,
) -> OrderByDirection {
  case in {
    Asc -> query.Asc
    Desc -> query.Desc
  }
}

pub fn order_asc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    True,
  )
}

pub fn order_asc_nulls_first(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    True,
  )
}

pub fn order_asc_replace(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    False,
  )
}

pub fn order_asc_nulls_first_replace(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    False,
  )
}

pub fn order_desc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    True,
  )
}

pub fn order_desc_nulls_first(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    True,
  )
}

pub fn order_desc_replace(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    False,
  )
}

pub fn order_desc_nulls_first_replace(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    False,
  )
}

pub fn order(
  query qry: Combined,
  by ordb: String,
  direction dir: CombinedQueryOrderByDirection,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

pub fn order_replace(
  query qry: Combined,
  by ordb: String,
  direction dir: CombinedQueryOrderByDirection,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}
