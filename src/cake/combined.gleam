//// A DSL to build combined queries, such as:
////
//// - `UNION`
//// - `UNION ALL`
//// - `EXCEPT`
//// - `EXCEPT ALL`
//// - `INTERSECT`
//// - `INTERSECT ALL`
////
//// ## Aliases
////
//// ```gleam
//// import cake/combined as c
//// import cake/select as s
//// import cake/where as w
//// ```
////
//// ---
////
//// ## Query Lifecycle
////
//// ```mermaid
//// flowchart LR
////     A[s.new + query builders] --> B{set operation}
////     B -->|union| C[c.union / c.unions]
////     B -->|union_all| D[c.union_all / c.unions_all]
////     B -->|except| E[c.except / c.excepts]
////     B -->|except_all| F[c.except_all / c.excepts_all]
////     B -->|intersect| G[c.intersect / c.intersects]
////     B -->|intersect_all| H[c.intersect_all / c.intersects_all]
////     C --> I[limit / offset / order_by]
////     D --> I
////     E --> I
////     F --> I
////     G --> I
////     H --> I
////     I --> J[c.epilog / c.comment]
////     J --> K[c.to_query]
//// ```
////
//// ---
////
//// ## Set Operations
////
//// All set operations take at least two `Select` queries (converted via
//// `s.to_query`) and return a `Combined` value. The `_all` variants accept
//// two queries; the plural variants accept a list of additional queries.
////
//// ### `union(a, b) -> Combined` / `unions(a, b, rest) -> Combined`
////
//// `UNION` — distinct rows from both queries.
////
//// ```gleam
//// let q1 =
////   s.new()
////   |> s.from_table("users")
////   |> s.col("name")
////   |> s.to_query
////
//// let q2 =
////   s.new()
////   |> s.from_table("customers")
////   |> s.col("name")
////   |> s.to_query
////
//// c.union(q1, q2)
//// // SELECT name FROM users UNION SELECT name FROM customers
//// ```
////
//// ### `union_all(a, b) -> Combined` / `unions_all(a, b, rest) -> Combined`
////
//// `UNION ALL` — all rows from both queries (no deduplication).
////
//// ```gleam
//// c.union_all(q1, q2)
//// // SELECT name FROM users UNION ALL SELECT name FROM customers
//// ```
////
//// ### `except(a, b) -> Combined` / `excepts(a, b, rest) -> Combined`
////
//// `EXCEPT` — rows in the first query that do not appear in the second.
////
//// ```gleam
//// c.except(q1, q2)
//// // SELECT name FROM users EXCEPT SELECT name FROM customers
//// ```
////
//// ### `except_all(a, b) -> Combined` / `excepts_all(a, b, rest) -> Combined`
////
//// `EXCEPT ALL` — rows in the first query that do not appear in the second,
//// including duplicates.
////
//// > Not supported by 🪶 SQLite.
////
//// ```gleam
//// c.except_all(q1, q2)
//// // SELECT name FROM users EXCEPT ALL SELECT name FROM customers
//// ```
////
//// ### `intersect(a, b) -> Combined` / `intersects(a, b, rest) -> Combined`
////
//// `INTERSECT` — rows that appear in both queries.
////
//// ```gleam
//// c.intersect(q1, q2)
//// // SELECT name FROM users INTERSECT SELECT name FROM customers
//// ```
////
//// ### `intersect_all(a, b) -> Combined` / `intersects_all(a, b, rest) -> Combined`
////
//// `INTERSECT ALL` — rows that appear in both queries, including duplicates.
////
//// > Not supported by 🪶 SQLite.
////
//// ```gleam
//// c.intersect_all(q1, q2)
//// // SELECT name FROM users INTERSECT ALL SELECT name FROM customers
//// ```
////
//// ---
////
//// ## Helper
////
//// ### `get_queries(combined) -> List(Select)`
////
//// Extracts the original `Select` queries from a `Combined` value.
////
//// ```gleam
//// c.get_queries(combined_query)
//// ```
////
//// ---
////
//// ## LIMIT & OFFSET
////
//// Applied to the result of the combined query (not to individual sub-queries).
////
//// | Function                   | Effect               |
//// | ------                   | ------               |
//// | `limit(query, n)`        | Set LIMIT            |
//// | `no_limit(query)`        | Remove LIMIT         |
//// | `get_limit(query)`       | Get current LIMIT    |
//// | `offset(query, n)`       | Set OFFSET           |
//// | `no_offset(query)`       | Remove OFFSET        |
//// | `get_offset(query)`      | Get current OFFSET   |
////
//// ```gleam
//// c.union(q1, q2)
//// |> c.limit(10)
//// |> c.offset(20)
//// ```
////
//// ---
////
//// ## ORDER BY
////
//// Sorts the combined result set.
////
//// ### Direction
////
//// | Constructor | Description |
//// | --- | --- |
//// | `c.Asc` | Ascending |
//// | `c.Desc` | Descending |
////
//// ### Appending
////
//// | Function | Notes |
//// | --- | --- |
//// | `order_by_asc(query, col)` | Append ASC |
//// | `order_by_asc_nulls_first(query, col)` | ASC NULLS FIRST |
//// | `order_by_asc_nulls_last(query, col)` | ASC NULLS LAST |
//// | `order_by_desc(query, col)` | Append DESC |
//// | `order_by_desc_nulls_first(query, col)` | DESC NULLS FIRST |
//// | `order_by_desc_nulls_last(query, col)` | DESC NULLS LAST |
//// | `order_by(query, col, direction)` | Custom direction |
////
//// ### Replacing
////
//// | Function | Notes |
//// | --- | --- |
//// | `replace_order_by_asc(query, col)` | Replace all with ASC |
//// | `replace_order_by_asc_nulls_first(query, col)` | Replace with ASC NULLS FIRST |
//// | `replace_order_by_asc_nulls_last(query, col)` | Replace with ASC NULLS LAST |
//// | `replace_order_by_desc(query, col)` | Replace all with DESC |
//// | `replace_order_by_desc_nulls_first(query, col)` | Replace with DESC NULLS FIRST |
//// | `replace_order_by_desc_nulls_last(query, col)` | Replace with DESC NULLS LAST |
//// | `replace_order_by(query, col, direction)` | Replace with custom direction |
////
//// ### Removal / retrieval
////
//// | Function | Effect |
//// | --- | --- |
//// | `no_order_by(query)` | Remove ORDER BY |
//// | `get_order_by(query)` | Get current ORDER BY |
////
//// > **Note:** `NULLS FIRST` / `NULLS LAST` are not supported out of the box by
//// > 🦭 MariaDB or 🐬 MySQL.
////
//// ```gleam
//// c.union(q1, q2)
//// |> c.order_by_desc("name")
//// // SELECT ... UNION SELECT ... ORDER BY name DESC
//// ```
////
//// ---
////
//// ## Epilog and Comment
////
//// An **epilog** is appended verbatim to the end of the generated SQL.
//// A **comment** is placed at the very end as a SQL `--` comment.
////
//// | Function | Effect |
//// | --- | --- |
//// | `epilog(query, text)` | Append epilog |
//// | `no_epilog(query)` | Remove epilog |
//// | `get_epilog(query)` | Get current epilog |
//// | `comment(query, text)` | Append comment |
//// | `no_comment(query)` | Remove comment |
//// | `get_comment(query)` | Get current comment |
////
//// ```gleam
//// c.union(q1, q2)
//// |> c.epilog("FOR UPDATE")
//// |> c.comment("fetching locked rows")
//// // SELECT ... UNION SELECT ... FOR UPDATE -- fetching locked rows
//// ```
////
//// ---
////
//// ## Converting to a Query
////
//// ### `to_query(combined) -> ReadQuery`
////
//// Converts a `Combined` into a `ReadQuery` suitable for passing to an adapter.
////
//// ```gleam
//// c.union(q1, q2)
//// |> c.limit(10)
//// |> c.to_query
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/combined as c
//// import cake/select as s
//// import cake/where as w
////
//// let active_users =
////   s.new()
////   |> s.from_table("users")
////   |> s.select_cols(["id", "name", "active"])
////   |> s.where(w.eq(w.col("active"), w.bool(True)))
////   |> s.to_query
////
//// let active_customers =
////   s.new()
////   |> s.from_table("customers")
////   |> s.select_cols(["id", "name", "active"])
////   |> s.where(w.eq(w.col("active"), w.bool(True)))
////   |> s.to_query
////
//// c.unions(active_users, active_customers, [
////   s.new()
////   |> s.from_table("admins")
////   |> s.select_cols(["id", "name", "active"])
////   |> s.where(w.eq(w.col("active"), w.bool(True)))
////   |> s.to_query,
//// ])
//// |> c.order_by_asc("name")
//// |> c.limit(50)
//// |> c.to_query
//// // (SELECT id, name, active FROM users WHERE active = $1)
//// // UNION
//// // (SELECT id, name, active FROM customers WHERE active = $2)
//// // UNION
//// // (SELECT id, name, active FROM admins WHERE active = $3)
//// // ORDER BY name ASC
//// // LIMIT 50
//// ```
////
////
//// <!-- html assets for docs gen -->
//// <style>
////  .page {
////    display: block;
////  }
////  .content {
////    width: auto;
////    max-width: none;
////  }
//// </style>
//// <!--<script src="https://cdn.jsdelivr.net/npm/@mermaid-js/tiny@11/dist/mermaid.tiny.js"></script>-->
//// <script
////   src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"
////   integrity="sha256-cBN+d7snO7LvlyuG6LBADMqL5TyyW/xFkRoYbcmGZd4="
////   crossorigin="anonymous"
//// ></script>
//// <script>
//// (callback => document.readyState !== 'loading' ? callback() : document.addEventListener('DOMContentLoaded', callback, { once: true }))(() => {
////   mermaid.initialize({ startOnLoad: false })
////   mermaid.run({
////     querySelector: ".language-mermaid",
////   })
//// })
//// </script>
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
    order_by: [order_by |> OrderByColumn(direction)] |> OrderBy,
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
    order_by: [order_by |> OrderByColumn(direction)] |> OrderBy,
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
