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
  type Join, type JoinKind, type Query, type Where, CrossJoin, FullJoin,
  InnerJoin, JoinSubQuery, JoinTable, LeftJoin, RightJoin,
}

pub fn table(table_name tbl_nm: String) -> JoinKind {
  tbl_nm |> JoinTable
}

pub fn sub_query(sub_query sq: Query) -> JoinKind {
  sq |> JoinSubQuery
}

pub fn inner(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> InnerJoin(alias: als, on: on)
}

/// Also called `LEFT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE a.key IS NULL` to make it _exclusive_.
///
pub fn left(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> LeftJoin(alias: als, on: on)
}

/// Also called `RIGHT OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE b.key IS NULL` to make it _exclusive_.
///
pub fn right(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> RightJoin(alias: als, on: on)
}

/// Also called `FULL OUTER JOIN`.
///
/// _Inclusive_ by default.
///
/// Set `on` to `WHERE a.key IS NULL OR b.key IS NULL` to make it _exclusive_.
///
pub fn full(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> FullJoin(alias: als, on: on)
}

/// Also called _cartesian product_.
///
pub fn cross(with wth: JoinKind, alias als: String) -> Join {
  wth |> CrossJoin(alias: als)
}
