import cake/internal/query.{
  type CombinedQuery, type OrderByDirectionPart, type Query, type SelectQuery,
  Asc, AscNullsFirst, Combined, CombinedQuery, Desc, DescNullsFirst, Except,
  ExceptAll, Intersect, IntersectAll, OrderByColumnPart, Union, UnionAll,
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

pub fn set_limit(query qry: CombinedQuery, limit lmt: Int) -> CombinedQuery {
  let lmt_offst = query.limit_new(lmt)
  CombinedQuery(..qry, limit_offset: lmt_offst)
}

pub fn set_limit_and_offset(
  query qry: CombinedQuery,
  limit lmt: Int,
  offset offst: Int,
) -> CombinedQuery {
  let lmt_offst = query.limit_offset_new(limit: lmt, offset: offst)
  CombinedQuery(..qry, limit_offset: lmt_offst)
}

// ▒▒▒ ORDER BY ▒▒▒

pub fn order_asc(query qry: CombinedQuery, by ordb: String) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, Asc), True)
}

pub fn order_asc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, AscNullsFirst), True)
}

pub fn order_asc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, Asc), False)
}

pub fn order_asc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, AscNullsFirst), False)
}

pub fn order_desc(query qry: CombinedQuery, by ordb: String) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, Desc), True)
}

pub fn order_desc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, DescNullsFirst), True)
}

pub fn order_desc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, Desc), False)
}

pub fn order_desc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, DescNullsFirst), False)
}

pub fn order(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, dir), True)
}

pub fn order_replace(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> CombinedQuery {
  qry |> query.combined_order_by(OrderByColumnPart(ordb, dir), False)
}
