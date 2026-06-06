//// Functions to build `JOIN` clauses of SQL queries.
////
//// Builds `JOIN` clauses for `SELECT`, `UPDATE`, and `DELETE` queries.
//// Tables, views and sub-queries can be joined together.
////
//// ## Aliases
////
//// ```gleam
//// import cake/join as j
//// import cake/where as w
//// ```
////
//// ---
////
//// ## Concept
////
//// A `Join` is constructed in two steps:
////
//// 1. Build a **target** — the table or sub-query to join against.
//// 2. Wrap it in a **join type** with an `ON` condition and an alias.
////
//// ```mermaid
//// flowchart LR
////     A[j.table / j.sub_query] --> B[JoinTarget]
////     B --> C[j.inner / j.left / j.right / j.full / j.cross]
////     C --> D[Join]
////     D --> E[s.join / u.join / d.join]
//// ```
////
//// ---
////
//// ## Step 1: Build a JoinTarget
////
//// ### `table(table_name) -> JoinTarget`
////
//// ```gleam
//// j.table("users")
//// ```
////
//// ### `sub_query(query) -> JoinTarget`
////
//// ```gleam
//// import cake/select as s
////
//// let sub =
////   s.new()
////   |> s.from_table("orders")
////   |> s.select_cols(["user_id", "SUM(amount)"])
////   |> s.group_by("user_id")
////   |> s.to_query
////
//// j.sub_query(sub)
//// ```
////
//// ---
////
//// ## Step 2: Choose a Join Type
////
//// All join constructors take:
////
//// - `with` — a `JoinTarget`
//// - `on` — a `Where` condition (from `cake/where`)
//// - `alias` — a SQL alias for the joined table/sub-query
////
//// ### `inner(with, on, alias) -> Join`
////
//// Returns only rows with matches on both sides.
////
//// ```gleam
//// j.inner(
////   with: j.table("orders"),
////   on: w.eq(w.col("users.id"), w.col("orders.user_id")),
////   alias: "orders",
//// )
//// // INNER JOIN orders ON users.id = orders.user_id
//// ```
////
//// ### `left(with, on, alias) -> Join`
////
//// Returns all rows from the left table, with `NULL` for non-matching right rows.
//// To make it **exclusive** (only left rows with no right match), use the normal
//// join condition in `on` and add `WHERE right.key IS NULL` as a query `WHERE`
//// filter.
////
//// ```gleam
//// j.left(
////   with: j.table("profiles"),
////   on: w.eq(w.col("users.id"), w.col("profiles.user_id")),
////   alias: "profiles",
//// )
//// // LEFT JOIN profiles ON users.id = profiles.user_id
//// ```
////
//// ### `right(with, on, alias) -> Join`
////
//// Returns all rows from the right table, with `NULL` for non-matching left rows.
////
//// ### `full(with, on, alias) -> Join`
////
//// Returns all rows from both tables, with `NULL` fill on non-matching sides.
////
//// ### `cross(with, alias) -> Join`
////
//// Cartesian product — every combination of rows. No `ON` condition.
////
//// ```gleam
//// j.cross(with: j.table("sizes"), alias: "sizes")
//// // CROSS JOIN sizes
//// ```
////
//// ---
////
//// ## Join type summary
////
//// ```mermaid
//// flowchart TD
////     A[Join types] --> B[INNER JOIN\nMatching rows only]
////     A --> C[LEFT JOIN\nAll left + matching right]
////     A --> D[RIGHT JOIN\nAll right + matching left]
////     A --> E[FULL JOIN\nAll rows both sides]
////     A --> F[CROSS JOIN\nCartesian product]
////     A --> G[LATERAL joins\nPG + MySQL only]
//// ```
////
//// | Function             | SQL                              | Notes              |
//// | ----------           | -------------------------------- | ----------         |
//// | `inner(with, on, alias)`     | `INNER JOIN`                     |                       |
//// | `left(with, on, alias)`      | `LEFT JOIN`                      |                       |
//// | `right(with, on, alias)`     | `RIGHT JOIN`                     |                       |
//// | `full(with, on, alias)`      | `FULL JOIN`                      |                       |
//// | `cross(with, alias)`         | `CROSS JOIN`                     | No ON clause          |
//// | `inner_lateral(with, alias)` | `INNER JOIN LATERAL ... ON TRUE` | 🐘 PG 9.3+ / 🐬 MySQL |
//// | `left_lateral(with, alias)`  | `LEFT JOIN LATERAL ... ON TRUE`  | 🐘 PG 9.3+ / 🐬 MySQL |
//// | `cross_lateral(with, alias)` | `CROSS JOIN LATERAL`             | 🐘 PG 9.3+ / 🐬 MySQL |
////
//// ---
////
//// ## LATERAL Joins
////
//// `LATERAL` joins allow the right-hand sub-query to reference columns from the
//// left-hand table. This is particularly useful for per-row sub-queries such as
//// finding the N most recent related records.
////
//// > ⚠️ `LATERAL` joins are not optimised by the query planner and can be very
//// > slow on large datasets, especially when the sub-query returns many rows.
////
//// ```gleam
//// import cake/select as s
//// import cake/join as j
//// import cake/where as w
////
//// let latest_order =
////   s.new()
////   |> s.from_table("orders")
////   |> s.col("amount")
////   |> s.where(w.eq(w.col("orders.user_id"), w.col("users.id")))
////   |> s.order_by_desc("created_at")
////   |> s.limit(1)
////   |> s.to_query
////
//// s.new()
//// |> s.from_table("users")
//// |> s.join(j.left_lateral(with: j.sub_query(latest_order), alias: "lo"))
//// |> s.select_cols(["users.name", "lo.amount"])
//// |> s.to_query
//// ```
////
//// ---
////
//// ## Exclusive Join Patterns
////
//// Exclusive joins return rows that exist in **only one** side of the join.
//// They are expressed using a standard `left`/`right`/`full` join with the
//// normal `ON` condition, then filtering rows in the query `WHERE` clause with
//// an `IS NULL` check on the outer side's key.
////
//// ```mermaid
//// flowchart LR
////     A[Exclusive LEFT\nonly left has no right match] -->|add WHERE b.key IS NULL| B[j.left ... + w.is_null]
////     C[Exclusive RIGHT\nonly right has no left match] -->|add WHERE a.key IS NULL| D[j.right ... + w.is_null]
////     E[Exclusive FULL\nrows with no match on either side] -->|add WHERE a.key IS NULL OR b.key IS NULL| F[j.full ... + or-is-null]
//// ```
////
//// ```gleam
//// // Users who have NO orders
//// j.left(
////   with: j.table("orders"),
////   on: w.eq(w.col("users.id"), w.col("orders.user_id")),
////   alias: "orders",
//// )
//// // Then filter in WHERE: w.is_null(w.col("orders.user_id"))
//// ```
////
//// ---
////
//// ## Self Join
////
//// Join a table to itself by using the same table name with a different alias.
////
//// ```gleam
//// j.inner(
////   with: j.table("employees"),
////   on: w.eq(w.col("e.manager_id"), w.col("manager.id")),
////   alias: "manager",
//// )
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/select as s
//// import cake/join as j
//// import cake/where as w
////
//// s.new()
//// |> s.from_table("orders")
//// |> s.select_cols(["orders.id", "users.name", "products.title"])
//// |> s.joins([
////   j.inner(
////     with: j.table("users"),
////     on: w.eq(w.col("orders.user_id"), w.col("users.id")),
////     alias: "users",
////   ),
////   j.left(
////     with: j.table("products"),
////     on: w.eq(w.col("orders.product_id"), w.col("products.id")),
////     alias: "products",
////   ),
//// ])
//// |> s.where(w.eq(w.col("orders.status"), w.string("paid")))
//// |> s.to_query
//// ```
////
////
//// ## Supported join kinds
////
//// - `INNER JOIN`
//// - `LEFT JOIN`, inclusive, same as `LEFT OUTER JOIN`,
//// - `RIGHT JOIN`, inclusive, same as `RIGHT OUTER JOIN`,
//// - `FULL JOIN`, inclusive, same as `FULL OUTER JOIN`,
//// - `CROSS JOIN`
////
//// You can also build following joins using the provided query builder
//// functions combined with a `WHERE` filter on the outer side:
////
//// - `SELF JOIN`: Use the same table, view, or sub-query with a different
////    alias.
//// - `EXCLUSIVE LEFT JOIN`: `LEFT JOIN` + `WHERE b.key IS NULL` filter
//// - `EXCLUSIVE RIGHT JOIN`: `RIGHT JOIN` + `WHERE a.key IS NULL` filter
//// - `EXCLUSIVE FULL JOIN`: `FULL JOIN` + `WHERE a.key IS NULL OR b.key IS NULL` filter
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
  CrossJoin, CrossJoinLateral, FullJoin, InnerJoin, InnerJoinLateralOnTrue,
  JoinSubQuery, JoinTable, LeftJoin, LeftJoinLateralOnTrue, RightJoin,
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Join =
  read_query.Join

pub type JoinTarget =
  read_query.JoinTarget

pub type ReadQuery =
  read_query.ReadQuery

pub type Where =
  read_query.Where

/// Create a `JOIN` target from a table name.
///
pub fn table(table_name table_name: String) -> JoinTarget {
  table_name |> JoinTable
}

/// Create a `JOIN` target from a sub-query.
///
pub fn sub_query(sub_query sub_query: ReadQuery) -> JoinTarget {
  sub_query |> JoinSubQuery
}

/// Create an `INNER JOIN`.
///
pub fn inner(with with: JoinTarget, on on: Where, alias alias: String) -> Join {
  with |> InnerJoin(alias:, on:)
}

/// Creates a `LEFT JOIN`.
///
/// Also called `LEFT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// To make it _exclusive_ (only left rows with no right match), use the
/// normal join condition in `on` and add `WHERE b.key IS NULL` as a
/// `WHERE` filter on the query.
///
pub fn left(with with: JoinTarget, on on: Where, alias alias: String) -> Join {
  with |> LeftJoin(alias:, on:)
}

/// Creates a `RIGHT JOIN`.
///
/// Also called `RIGHT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// To make it _exclusive_ (only right rows with no left match), use the
/// normal join condition in `on` and add `WHERE a.key IS NULL` as a
/// `WHERE` filter on the query.
///
pub fn right(with with: JoinTarget, on on: Where, alias alias: String) -> Join {
  with |> RightJoin(alias:, on:)
}

/// Creates a `FULL JOIN`.
///
/// Also called `FULL OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// To make it _exclusive_ (only rows with no match on either side), use
/// the normal join condition in `on` and add
/// `WHERE a.key IS NULL OR b.key IS NULL` as a `WHERE` filter on the query.
///
pub fn full(with with: JoinTarget, on on: Where, alias alias: String) -> Join {
  with |> FullJoin(alias:, on:)
}

/// Creates a `CROSS JOIN`.
///
/// Also called _cartesian product_.
///
pub fn cross(with with: JoinTarget, alias alias: String) -> Join {
  with |> CrossJoin(alias:)
}

/// Creates a `INNER JOIN LATERAL ... ON TRUE`.
///
/// ⚠️⚠️⚠️
///
/// CAUTION: `LATERAL` joins are not optimized by the query planner,
/// and can be very slow on large datasets, especially when the sub-query
/// returns many rows.
///
/// ⚠️⚠️⚠️
///
/// See <https://www.postgresql.org/docs/9.3/sql-select.html#SQL-FROM> for an
/// explanation on how `LATERAL` works.
///
/// Any filtering must be done in WHERE clauses as the JOIN ON clause is always
/// TRUE when calling this function.
///
/// NOTICE: `LATERAL` is supported by 🐘PostgreSQL 9.3+ and recent 🐬MySQL
/// versions.
///
pub fn inner_lateral(with with: JoinTarget, alias alias: String) -> Join {
  with |> InnerJoinLateralOnTrue(alias:)
}

/// Creates a `LEFT JOIN LATERAL ... ON TRUE`.
///
/// ⚠️⚠️⚠️
///
/// CAUTION: `LATERAL` joins are not optimized by the query planner,
/// and can be very slow on large datasets, especially when the sub-query
/// returns many rows.
///
/// ⚠️⚠️⚠️
///
/// See <https://www.postgresql.org/docs/9.3/sql-select.html#SQL-FROM> for an
/// explanation on how `LATERAL` works.
///
/// Any filtering must be done in WHERE clauses as the JOIN ON clause is always
/// TRUE when calling this function.
///
/// NOTICE: `LATERAL` is supported by 🐘PostgreSQL 9.3+ and recent 🐬MySQL
/// versions.
///
pub fn left_lateral(with with: JoinTarget, alias alias: String) -> Join {
  with |> LeftJoinLateralOnTrue(alias:)
}

/// Creates a `CROSS JOIN LATERAL`.
///
/// ⚠️⚠️⚠️
///
/// CAUTION: `LATERAL` joins are not optimized by the query planner,
/// and can be very slow on large datasets, especially when the sub-query
/// returns many rows.
///
/// ⚠️⚠️⚠️
///
/// See <https://www.postgresql.org/docs/9.3/sql-select.html#SQL-FROM> for an
/// explanation on how `LATERAL` works.
///
/// NOTICE: `LATERAL` is supported by 🐘PostgreSQL 9.3+ and recent 🐬MySQL
/// versions.
///
pub fn cross_lateral(with with: JoinTarget, alias alias: String) -> Join {
  with |> CrossJoinLateral(alias:)
}
