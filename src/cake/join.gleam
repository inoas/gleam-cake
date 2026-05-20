//// Functions to build `JOIN` clauses of SQL queries.
////
//// Tables, views and sub-queries can be joined together.
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
//// functions:
////
//// - `SELF JOIN`: Use the same table, view, or sub-query with a different
////    alias.
//// - `EXCLUSIVE LEFT JOIN`: `WHERE b.key IS NULL`
//// - `EXCLUSIVE RIGHT JOIN`: `WHERE a.key IS NULL`
//// - `EXCLUSIVE FULL JOIN`: `WHERE a.key IS NULL OR b.key IS NULL`
////

import cake/internal/read_query.{
  CrossJoin, CrossJoinLateral, FullJoin, InnerJoin, InnerJoinLateralOnTrue,
  JoinSubQuery, JoinTable, LeftJoin, LeftJoinLateralOnTrue, RightJoin,
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
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
/// Set `on` to `WHERE a.key IS NULL` to make it _exclusive_.
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
/// Set `on` to `WHERE b.key IS NULL` to make it _exclusive_.
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
/// Set `on` to `WHERE a.key IS NULL OR b.key IS NULL` to make it _exclusive_.
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
