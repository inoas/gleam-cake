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

import cake/internal/query.{
  type Join, type JoinTarget, type Query, type Where, CrossJoin, FullJoin,
  InnerJoin, JoinSubQuery, JoinTable, LeftJoin, RightJoin,
}

/// Create a `JOIN` target from a table name.
///
pub fn table(table_name tbl_nm: String) -> JoinTarget {
  tbl_nm |> JoinTable
}

/// Create a `JOIN` target from a sub-query.
///
pub fn sub_query(sub_query sq: Query) -> JoinTarget {
  sq |> JoinSubQuery
}

/// Create an `INNER JOIN`.
///
pub fn inner(with wth: JoinTarget, on on: Where, alias als: String) -> Join {
  wth |> InnerJoin(alias: als, on: on)
}

/// Creates a `LEFT JOIN`.
///
/// Also called `LEFT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE a.key IS NULL` to make it _exclusive_.
///
pub fn left(with wth: JoinTarget, on on: Where, alias als: String) -> Join {
  wth |> LeftJoin(alias: als, on: on)
}

/// Creates a `RIGHT JOIN`.
///
/// Also called `RIGHT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE b.key IS NULL` to make it _exclusive_.
///
pub fn right(with wth: JoinTarget, on on: Where, alias als: String) -> Join {
  wth |> RightJoin(alias: als, on: on)
}

/// Creates a `FULL JOIN`.
///
/// Also called `FULL OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE a.key IS NULL OR b.key IS NULL` to make it _exclusive_.
///
pub fn full(with wth: JoinTarget, on on: Where, alias als: String) -> Join {
  wth |> FullJoin(alias: als, on: on)
}

/// Creates a `CROSS JOIN`.
///
/// Also called _cartesian product_.
///
pub fn cross(with wth: JoinTarget, alias als: String) -> Join {
  wth |> CrossJoin(alias: als)
}
