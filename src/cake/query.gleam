import cake/query/select_query.{type SelectQuery}
import cake/query/union_query.{type UnionQuery}

pub type Query {
  SelectQuery(SelectQuery)
  UnionQuery(UnionQuery)
}
