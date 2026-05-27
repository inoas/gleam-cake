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
//// - 🪶SQLite does not support `EXCEPT ALL` and `INTERSECT ALL`.
////

import cake/internal/read_query.{
  Combined, CombinedQuery, Comment, Epilog, ExceptAll, ExceptDistinct,
  IntersectAll, IntersectDistinct, NoComment, NoEpilog, NoLimit, NoOffset,
  NoOrderBy, OrderBy, OrderByColumn, UnionAll, UnionDistinct,
}
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Combined =
  read_query.Combined

pub type Comment =
  read_query.Comment

pub type Epilog =
  read_query.Epilog

pub type Limit =
  read_query.Limit

pub type Offset =
  read_query.Offset

pub type OrderBy =
  read_query.OrderBy

pub type OrderByDirection =
  read_query.OrderByDirection

pub type ReadQuery =
  read_query.ReadQuery

pub type Select =
  read_query.Select

/// Creates a `ReadQuery` from a `Combined` `ReadQuery`.
///
pub fn to_query(combined combined: Combined) -> ReadQuery {
  combined |> CombinedQuery
}

// ▒▒▒ Combined Kind ▒▒▒

/// Creates a `UNION` query out of two queries as a `Combined` `ReadQuery`.
///
pub fn union(query_a query_a: Select, query_b query_b: Select) -> Combined {
  UnionDistinct |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates a `UNION` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
pub fn unions(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  UnionDistinct
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Creates a `UNION ALL` query out of two queries as a `Combined` `ReadQuery`.
///
pub fn union_all(query_a query_a: Select, query_b query_b: Select) -> Combined {
  UnionAll |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates a `UNION ALL` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
pub fn unions_all(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  UnionAll
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Creates an `EXCEPT` query out of two queries as a `Combined` `ReadQuery`.
///
pub fn except(query_a query_a: Select, query_b query_b: Select) -> Combined {
  ExceptDistinct |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates an `EXCEPT` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
pub fn excepts(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  ExceptDistinct
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Creates an `EXCEPT ALL` query out of two queries as a `Combined`
/// `ReadQuery`.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn except_all(
  query_a query_a: Select,
  query_b query_b: Select,
) -> Combined {
  ExceptAll |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates an `EXCEPT ALL` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn excepts_all(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  ExceptAll
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Creates an `INTERSECT` query out of two queries as a `Combined` `ReadQuery`.
///
pub fn intersect(query_a query_a: Select, query_b query_b: Select) -> Combined {
  IntersectDistinct
  |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates an `INTERSECT` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
pub fn intersects(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  IntersectDistinct
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Creates an `INTERSECT ALL` query out of two queries as a `Combined`
/// `ReadQuery`.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn intersect_all(
  query_a query_a: Select,
  query_b query_b: Select,
) -> Combined {
  IntersectAll |> read_query.combined_query_new(queries: [query_a, query_b])
}

/// Creates an `INTERSECT ALL` query out of two or more queries as a `Combined`
/// `ReadQuery`.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn intersects_all(
  query_a query_a: Select,
  query_b query_b: Select,
  more_queries more_queries: List(Select),
) -> Combined {
  IntersectAll
  |> read_query.combined_query_new(queries: [query_a, query_b, ..more_queries])
}

/// Gets the queries from a `Combined` `ReadQuery`.
///
pub fn get_queries(combined combined: Combined) -> List(Select) {
  combined.queries
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Combined` `ReadQuery`.
///
pub fn limit(query query: Combined, limit limit: Int) -> Combined {
  let limit = read_query.limit_new(limit:)
  Combined(..query, limit:)
}

/// Removes `Limit` from the `Combined` `ReadQuery`.
///
pub fn no_limit(query query: Combined) -> Combined {
  Combined(..query, limit: NoLimit)
}

/// Gets `Limit` in the `Combined` `ReadQuery`.
///
pub fn get_limit(query query: Combined) -> Limit {
  query.limit
}

/// Sets an `Offset` in the `Combined` `ReadQuery`.
///
pub fn offset(query query: Combined, offset offset: Int) -> Combined {
  let offset = read_query.offset_new(offset:)
  Combined(..query, offset:)
}

/// Removes `Offset` from the `Combined` `ReadQuery`.
///
pub fn no_offset(query query: Combined) -> Combined {
  Combined(..query, offset: NoOffset)
}

/// Gets `Offset` in the `Combined` `ReadQuery`.
///
pub fn get_offset(query query: Combined) -> Offset {
  query.offset
}

// ▒▒▒ ORDER BY ▒▒▒

/// Defines the direction of an `OrderBy`.
///
pub type Direction {
  Asc
  Desc
}

fn map_order_by_direction_constructor(in in: Direction) -> OrderByDirection {
  case in {
    Asc -> read_query.Asc
    Desc -> read_query.Desc
  }
}

/// Creates or appends an ascending `OrderBy`.
///
pub fn order_by_asc(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.Asc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_asc_nulls_first(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.AscNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.AscNullsLast)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` with a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.Asc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` with a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_asc_nulls_first(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.AscNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` with a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_asc_nulls_last(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.AscNullsLast)] |> OrderBy,
    append: False,
  )
}

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.Desc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_desc_nulls_first(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.DescNullsFirst)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_desc_nulls_last(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.DescNullsLast)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` with a single descending order.
///
pub fn replace_order_by_desc(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.Desc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` with a single descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_desc_nulls_first(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.DescNullsFirst)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` with a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_desc_nulls_last(
  query query: Combined,
  order_by order_by: String,
) -> Combined {
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(read_query.DescNullsLast)] |> OrderBy,
    append: False,
  )
}

/// Creates or appends an `OrderBy` for a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  query query: Combined,
  order_by order_by: String,
  direction direction: Direction,
) -> Combined {
  let direction = direction |> map_order_by_direction_constructor
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(direction:)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` with a column with a direction.
///
pub fn replace_order_by(
  query query: Combined,
  order_by order_by: String,
  direction direction: Direction,
) -> Combined {
  let direction = direction |> map_order_by_direction_constructor
  query
  |> read_query.combined_order_by(
    order_by: [order_by |> OrderByColumn(direction:)] |> OrderBy,
    append: False,
  )
}

/// Removes the `OrderBy` from the `Combined` read_query.
///
pub fn no_order_by(query query: Combined) -> Combined {
  Combined(..query, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Combined` read_query.
///
pub fn get_order_by(query query: Combined) -> OrderBy {
  query.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Combined` read_query.
///
pub fn epilog(query query: Combined, epilog epilog: String) -> Combined {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Combined(..query, epilog: NoEpilog)
    _ -> Combined(..query, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Combined` read_query.
///
pub fn no_epilog(query query: Combined) -> Combined {
  Combined(..query, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Combined` read_query.
///
pub fn get_epilog(query query: Combined) -> Epilog {
  query.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Combined` read_query.
///
pub fn comment(query query: Combined, comment comment: String) -> Combined {
  let comment = comment |> string.trim
  case comment {
    "" -> Combined(..query, comment: NoComment)
    _ -> Combined(..query, comment: { " " <> comment } |> Comment)
  }
}

/// Removes the `Comment` from the `Combined` read_query.
///
pub fn no_comment(query query: Combined) -> Combined {
  Combined(..query, comment: NoComment)
}

/// Gets the `Comment` from the `Combined` read_query.
///
pub fn get_comment(query query: Combined) -> Comment {
  query.comment
}
