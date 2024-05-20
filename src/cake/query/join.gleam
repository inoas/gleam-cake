import cake/internal/query.{
  type Join, type JoinPart, type Query, type WherePart, CrossJoin, FullOuterJoin,
  InnerJoin, JoinSubQuery, JoinTable, LeftOuterJoin, RightOuterJoin,
}

pub fn table(table_name tbl: String) -> Join {
  tbl |> JoinTable
}

pub fn sub_query(sub_query sq: Query) -> Join {
  sq |> JoinSubQuery
}

pub fn cross(with wth: Join, alias als: String) -> JoinPart {
  CrossJoin(with: wth, alias: als)
}

pub fn inner(with wth: Join, alias als: String, on on: WherePart) -> JoinPart {
  InnerJoin(with: wth, alias: als, on: on)
}

pub fn left_outer(
  with wth: Join,
  alias als: String,
  on on: WherePart,
) -> JoinPart {
  LeftOuterJoin(with: wth, alias: als, on: on)
}

pub fn right_outer(
  with wth: Join,
  alias als: String,
  on on: WherePart,
) -> JoinPart {
  RightOuterJoin(with: wth, alias: als, on: on)
}

pub fn full_outer(
  with wth: Join,
  alias als: String,
  on on: WherePart,
) -> JoinPart {
  FullOuterJoin(with: wth, alias: als, on: on)
}
