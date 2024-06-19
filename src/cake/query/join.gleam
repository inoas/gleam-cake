//// Functions to build `JOIN` clauses of SQL queries.
////
//// Joined can be tables (including views) or sub-queries.
////
//// ## Supported kinds
////
//// - `INNER JOIN`
//// - `LEFT OUTER JOIN`
//// - `RIGHT OUTER JOIN`
//// - `FULL OUTER JOIN`
//// - `CROSS JOIN`
////

import cake/internal/query.{
  type Join, type JoinKind, type Query, type Where, CrossJoin, FullOuterJoin,
  InnerJoin, JoinSubQuery, JoinTable, LeftOuterJoin, RightOuterJoin,
}

pub fn table(table_name tbl_nm: String) -> JoinKind {
  tbl_nm |> JoinTable
}

pub fn sub_query(sub_query sq: Query) -> JoinKind {
  sq |> JoinSubQuery
}

pub fn cross(with wth: JoinKind, alias als: String) -> Join {
  wth |> CrossJoin(alias: als)
}

pub fn inner(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> InnerJoin(alias: als, on: on)
}

pub fn left_outer(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> LeftOuterJoin(alias: als, on: on)
}

pub fn right_outer(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> RightOuterJoin(alias: als, on: on)
}

pub fn full_outer(with wth: JoinKind, on on: Where, alias als: String) -> Join {
  wth |> FullOuterJoin(alias: als, on: on)
}
