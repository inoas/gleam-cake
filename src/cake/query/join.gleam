import cake/internal/query.{
  type Join, type JoinKind, type Query, type WherePart, CrossJoin, FullOuterJoin,
  InnerJoin, JoinSubQuery, JoinTable, LeftOuterJoin, RightOuterJoin,
}

pub fn table(table_name tbl: String) -> JoinKind {
  tbl |> JoinTable
}

pub fn sub_query(sub_query sq: Query) -> JoinKind {
  sq |> JoinSubQuery
}

pub fn cross(with wth: JoinKind, alias als: String) -> Join {
  CrossJoin(with: wth, alias: als)
}

pub fn inner(with wth: JoinKind, alias als: String, on on: WherePart) -> Join {
  InnerJoin(with: wth, alias: als, on: on)
}

pub fn left_outer(
  with wth: JoinKind,
  alias als: String,
  on on: WherePart,
) -> Join {
  LeftOuterJoin(with: wth, alias: als, on: on)
}

pub fn right_outer(
  with wth: JoinKind,
  alias als: String,
  on on: WherePart,
) -> Join {
  RightOuterJoin(with: wth, alias: als, on: on)
}

pub fn full_outer(
  with wth: JoinKind,
  alias als: String,
  on on: WherePart,
) -> Join {
  FullOuterJoin(with: wth, alias: als, on: on)
}
