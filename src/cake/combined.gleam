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
  IntersectDistinct, NoComment, NoEpilog, NoLimit, NoOffset, NoOrderBy, OrderBy,
  OrderByColumn, UnionAll, UnionDistinct,
}
import gleam/string

/// Creates a `Query` from a `Combined` query.
///
pub fn to_query(combined_query qry: Combined) -> Query {
  qry |> CombinedQuery
}

// ▒▒▒ Combined Kind ▒▒▒

/// Creates a `UNION` query out of two queries as a `Combined` query.
///
pub fn union(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  UnionDistinct |> query.combined_query_new([qry_a, qry_b])
}

/// Creates a `UNION` query out of two or more queries as a `Combined` query.
///
pub fn union_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  UnionDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Creates a `UNION ALL` query out of two queries as a `Combined` query.
///
pub fn union_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  UnionAll |> query.combined_query_new([qry_a, qry_b])
}

/// Creates a `UNION ALL` query out of two or more queries as a `Combined`
/// query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn union_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  UnionAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Creates an `EXCEPT` query out of two queries as a `Combined` query.
///
pub fn except(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  ExceptDistinct |> query.combined_query_new([qry_a, qry_b])
}

/// Creates an `EXCEPT` query out of two or more queries as a `Combined` query.
///
pub fn except_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  ExceptDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Creates an `EXCEPT ALL` query out of two queries as a `Combined` query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn except_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  ExceptAll |> query.combined_query_new([qry_a, qry_b])
}

/// Creates an `EXCEPT ALL` query out of two or more queries as a `Combined`
/// query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn except_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  ExceptAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Creates an `INTERSECT` query out of two queries as a `Combined` query.
///
pub fn intersect(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  IntersectDistinct |> query.combined_query_new([qry_a, qry_b])
}

/// Creates an `INTERSECT` query out of two or more queries as a `Combined`
/// query.
///
pub fn intersect_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  IntersectDistinct |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Creates an `INTERSECT ALL` query out of two queries as a `Combined` query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn intersect_all(query_a qry_a: Select, query_b qry_b: Select) -> Combined {
  IntersectAll |> query.combined_query_new([qry_a, qry_b])
}

/// Creates an `INTERSECT ALL` query out of two or more queries as a `Combined`
/// query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn intersect_all_many(
  query_a qry_a: Select,
  query_b qry_b: Select,
  more_queries mr_qrys: List(Select),
) -> Combined {
  IntersectAll |> query.combined_query_new([qry_a, qry_b, ..mr_qrys])
}

/// Gets the queries from a `Combined` query.
///
pub fn get_queries(combined_query qry: Combined) -> List(Select) {
  qry.queries
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Combined` query.
///
pub fn limit(query qry: Combined, limit lmt: Int) -> Combined {
  let lmt = lmt |> query.limit_new
  Combined(..qry, limit: lmt)
}

/// Removes `Limit` from the `Combined` query.
///
pub fn no_limit(query qry: Combined) -> Combined {
  Combined(..qry, limit: NoLimit)
}

/// Gets `Limit` in the `Combined` query.
///
pub fn get_limit(query qry: Combined) -> Limit {
  qry.limit
}

/// Sets an `Offset` in the `Combined` query.
///
pub fn offset(query qry: Combined, offst offst: Int) -> Combined {
  let offst = offst |> query.offset_new
  Combined(..qry, offset: offst)
}

/// Removes `Offset` from the `Combined` query.
///
pub fn no_offset(query qry: Combined) -> Combined {
  Combined(..qry, offset: NoOffset)
}

/// Gets `Offset` in the `Combined` query.
///
pub fn get_offset(query qry: Combined) -> Offset {
  qry.offset
}

// ▒▒▒ ORDER BY ▒▒▒

/// Defines the direction of an `OrderBy`.
///
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

/// Creates or appends an ascending `OrderBy`.
///
pub fn order_by_asc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
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

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.AscNullsFirst)]),
    append: True,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Asc)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
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

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
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

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
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

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
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

/// Replaces the `OrderBy` a single descending order.
///
pub fn replace_order_by_desc(query qry: Combined, by ordb: String) -> Combined {
  qry
  |> query.combined_order_by(
    by: OrderBy(values: [OrderByColumn(ordb, query.Desc)]),
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending order with `NULLS FIRST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` out of the box.
///
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

/// Replaces the `OrderBy` a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: MariaDB/MySQL do not support `NULLS LAST` out of the box.
///
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

/// Creates or appends an `OrderBy` a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  query qry: Combined,
  by ordb: String,
  direction dir: Direction,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), True)
}

/// Replaces the `OrderBy` a column with a direction.
///
pub fn replace_order_by(
  query qry: Combined,
  by ordb: String,
  direction dir: Direction,
) -> Combined {
  let dir = dir |> map_order_by_direction_constructor
  qry
  |> query.combined_order_by(OrderBy(values: [OrderByColumn(ordb, dir)]), False)
}

/// Removes the `OrderBy` from the `Combined` query.
///
pub fn no_order_by(query qry: Combined) -> Combined {
  Combined(..qry, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Combined` query.
///
pub fn get_order_by(query qry: Combined) -> OrderBy {
  qry.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Combined` query.
///
pub fn epilog(query qry: Combined, epilog eplg: String) -> Combined {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Combined(..qry, epilog: NoEpilog)
    _ -> Combined(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Combined` query.
///
pub fn no_epilog(query qry: Combined) -> Combined {
  Combined(..qry, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Combined` query.
///
pub fn get_epilog(query qry: Combined) -> Epilog {
  qry.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Combined` query.
///
pub fn comment(query qry: Combined, comment cmmnt: String) -> Combined {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Combined(..qry, comment: NoComment)
    _ -> Combined(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Removes the `Comment` from the `Combined` query.
///
pub fn no_comment(query qry: Combined) -> Combined {
  Combined(..qry, comment: NoComment)
}

/// Gets the `Comment` from the `Combined` query.
///
pub fn get_comment(query qry: Combined) -> Comment {
  qry.comment
}
