// TODO v1 module doc

import cake/internal/query.{
  type Combined, type Limit, type Offset, type OrderByDirection, type Query,
  type Select, Combined, CombinedQuery, Epilog, ExceptAll, ExceptDistinct,
  IntersectAll, IntersectDistinct, NoEpilog, OrderBy, OrderByColumn, UnionAll,
  UnionDistinct,
}
import gleam/string

pub fn to_query(combined_query qry: Combined) -> Query {
  qry |> CombinedQuery
}

// ▒▒▒ Combined Kind ▒▒▒

pub fn union(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  UnionDistinct |> query.combined_query_new([qry_a, qry_b])
}

pub fn union_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  UnionDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn union_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  UnionAll |> query.combined_query_new([qry_a, qry_b])
}

pub fn union_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  UnionAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn except(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  ExceptDistinct |> query.combined_query_new([qry_a, qry_b])
}

pub fn except_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  ExceptDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn except_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  ExceptAll |> query.combined_query_new([qry_a, qry_b])
}

pub fn except_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  ExceptAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn intersect(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  IntersectDistinct |> query.combined_query_new([qry_a, qry_b])
}

pub fn intersect_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  IntersectDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn intersect_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  IntersectAll |> query.combined_query_new([qry_a, qry_b])
}

pub fn intersect_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  IntersectAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

pub fn get_queries(combined_query qry: Combined) -> List(Select) {
  qry.queries
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

pub fn epilog(query qry: Combined, epilog eplg: String) -> Combined {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Combined(..qry, epilog: NoEpilog)
    _ -> Combined(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn epilog_remove(query qry: Combined) -> Combined {
  Combined(..qry, epilog: NoEpilog)
}
