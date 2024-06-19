// TODO v1 module doc
// TODO v1 tests

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

pub fn inner(with wth: JoinKind, alias als: String, on on: Where) -> Join {
  wth |> InnerJoin(alias: als, on: on)
}

pub fn left_outer(with wth: JoinKind, alias als: String, on on: Where) -> Join {
  wth |> LeftOuterJoin(alias: als, on: on)
}

pub fn right_outer(with wth: JoinKind, alias als: String, on on: Where) -> Join {
  wth |> RightOuterJoin(alias: als, on: on)
}

pub fn full_outer(with wth: JoinKind, alias als: String, on on: Where) -> Join {
  wth |> FullOuterJoin(alias: als, on: on)
}
