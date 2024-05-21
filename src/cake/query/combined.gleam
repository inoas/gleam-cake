import cake/internal/query.{
  type CombinedQuery, type LimitOffsetPart, type OrderByDirectionPart,
  type Query, type SelectQuery, Combined, CombinedQuery, Except, ExceptAll,
  Intersect, IntersectAll, OrderByColumnPart, Union, UnionAll,
}

pub fn to_query(combined_query qry: CombinedQuery) -> Query {
  qry |> Combined()
}

// ▒▒▒ Combined Kind ▒▒▒

pub fn union(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  Union |> query.combined_query_new(qrys)
}

pub fn union_all(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  UnionAll |> query.combined_query_new(qrys)
}

pub fn except(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  Except |> query.combined_query_new(qrys)
}

pub fn except_all(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  ExceptAll |> query.combined_query_new(qrys)
}

pub fn intersect(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  Intersect |> query.combined_query_new(qrys)
}

pub fn intersect_all(select_queries qrys: List(SelectQuery)) -> CombinedQuery {
  IntersectAll |> query.combined_query_new(qrys)
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

pub fn set_limit_and_offset(
  query qry: CombinedQuery,
  limit lmt: Int,
  offset offst: Int,
) -> CombinedQuery {
  let lmt_offst = query.limit_offset_new(limit: lmt, offset: offst)
  CombinedQuery(..qry, limit_offset: lmt_offst)
}

pub fn set_limit(query qry: CombinedQuery, limit lmt: Int) -> CombinedQuery {
  let lmt_offst = query.limit_new(lmt)
  CombinedQuery(..qry, limit_offset: lmt_offst)
}

pub fn set_offset(query qry: CombinedQuery, limit lmt: Int) -> CombinedQuery {
  let lmt_offst = query.offset_new(lmt)
  CombinedQuery(..qry, limit_offset: lmt_offst)
}

pub fn get_limit_and_offset(select_query qry: CombinedQuery) -> LimitOffsetPart {
  qry.limit_offset
}

// ▒▒▒ ORDER BY ▒▒▒

pub type CombinedOrderByDirectionPart {
  Asc
  Desc
}

fn map_order_by_direction_part_constructor(
  in: CombinedOrderByDirectionPart,
) -> OrderByDirectionPart {
  case in {
    Asc -> query.Asc
    Desc -> query.Desc
  }
}

pub fn order_asc(query qry: CombinedQuery, by ordb: String) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, query.Asc), True)
}

pub fn order_asc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry
  |> query.combined_order_by(OrderByColumnPart(ordb, query.AscNullsFirst), True)
}

pub fn order_asc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, query.Asc), False)
}

pub fn order_asc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry
  |> query.combined_order_by(
    OrderByColumnPart(ordb, query.AscNullsFirst),
    False,
  )
}

pub fn order_desc(query qry: CombinedQuery, by ordb: String) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, query.Desc), True)
}

pub fn order_desc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry
  |> query.combined_order_by(
    OrderByColumnPart(ordb, query.DescNullsFirst),
    True,
  )
}

pub fn order_desc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, query.Desc), False)
}

pub fn order_desc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry
  |> query.combined_order_by(
    OrderByColumnPart(ordb, query.DescNullsFirst),
    False,
  )
}

pub fn order(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: CombinedOrderByDirectionPart,
) -> CombinedQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.combined_order_by(OrderByColumnPart(ordb, dir), True)
}

pub fn order_replace(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: CombinedOrderByDirectionPart,
) -> CombinedQuery {
  let dir = dir |> map_order_by_direction_part_constructor
  qry |> query.combined_order_by(OrderByColumnPart(ordb, dir), False)
}
