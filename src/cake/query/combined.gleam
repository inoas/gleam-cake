//// A DSL to build combined queries, such as:
////
//// - `UNION`
//// - `UNION ALL`
//// - `EXCEPT`
//// - `EXCEPT ALL`
//// - `INTERSECT`
//// - `INTERSECT ALL`
////
//// ## Compatibility
////
//// - SQLite does not support `EXCEPT ALL` and `INTERSECT ALL`.
////

import cake/internal/query.{
  type Combined, type Comment, type Epilog, type Limit, type Offset,
  type OrderBy, type OrderByDirection, type Query, type Select, Combined,
  CombinedQuery, Comment, Epilog, ExceptAll, ExceptDistinct, IntersectAll,
  IntersectDistinct, NoComment, NoEpilog, OrderBy, OrderByColumn, UnionAll,
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

/// NOTICE: Not supported by SQLite.
///
pub fn except_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  ExceptAll |> query.combined_query_new([qry_a, qry_b])
}

/// NOTICE: Not supported by SQLite.
///
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

/// NOTICE: Not supported by SQLite.
///
pub fn intersect_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  IntersectAll |> query.combined_query_new([qry_a, qry_b])
}

/// NOTICE: Not supported by SQLite.
///
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

pub fn no_limit(query qry: Combined) -> Combined {
  Combined(..qry, limit: query.NoLimit)
}

pub fn offset(query qry: Combined, offst offst: Int) -> Combined {
  let offst = offst |> query.offset_new
  Combined(..qry, offset: offst)
}

pub fn get_offset(query qry: Combined) -> Offset {
  qry.offset
}

pub fn no_offset(query qry: Combined) -> Combined {
  Combined(..qry, offset: query.NoOffset)
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

pub fn order_by_asc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: True,
  )
}

pub fn order_by_asc_nulls_first(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: True,
  )
}

pub fn order_by_asc_nulls_last(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: True,
  )
}

pub fn replace_order_by_asc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: False,
  )
}

pub fn replace_order_by_asc_nulls_first(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: False,
  )
}

pub fn replace_order_by_asc_nulls_last(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: False,
  )
}

pub fn order_by_desc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: True,
  )
}

pub fn order_by_desc_nulls_first(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: True,
  )
}

pub fn order_by_desc_nulls_last(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: True,
  )
}

pub fn replace_order_by_desc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: False,
  )
}

pub fn replace_order_by_desc_nulls_first(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: False,
  )
}

pub fn replace_order_by_desc_nulls_last(
  query qry: Combined,
  by ordb: String,
) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.DescNullsFirst)]),
    append: False,
  )
}

pub fn order_by(
  query qry: Combined,
  by ordb: String,
  direction dir: Direction,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

pub fn replace_order_by(
  query qry: Combined,
  by ordb: String,
  direction dir: Direction,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}

pub fn get_order_by(query qry: Combined) -> OrderBy {
  qry.order_by
}

pub fn no_order_by(query qry: Combined) -> Combined {
  Combined(..qry, order_by: query.NoOrderBy)
}

// ▒▒▒ EPILOG ▒▒▒

pub fn epilog(query qry: Combined, epilog eplg: String) -> Combined {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Combined(..qry, epilog: NoEpilog)
    _ -> Combined(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn no_epilog(query qry: Combined) -> Combined {
  Combined(..qry, epilog: NoEpilog)
}

pub fn get_epilog(query qry: Combined) -> Epilog {
  qry.epilog
}

// ▒▒▒ COMMENT ▒▒▒

pub fn comment(query qry: Combined, comment cmmnt: String) -> Combined {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Combined(..qry, comment: NoComment)
    _ -> Combined(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

pub fn no_comment(query qry: Combined) -> Combined {
  Combined(..qry, comment: NoComment)
}

pub fn get_comment(query qry: Combined) -> Comment {
  qry.comment
}
