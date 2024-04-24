import cake/query/select_query.{type SelectQuery}

// List of SQL parts that will be used to build a union query.
pub opaque type UnionQuery {
  UnionQuery(select_queries: List(SelectQuery), flags: List(#(String, String)))
}

pub fn union_query_new(
  select_queries select_queries: List(SelectQuery),
) -> UnionQuery {
  UnionQuery(select_queries: select_queries, flags: [])
}
