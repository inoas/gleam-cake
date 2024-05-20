import cake/internal/query.{type CombinedQuery, type Query, Combined}

pub fn to_query(combined_query qry: CombinedQuery) -> Query {
  qry |> Combined()
}
