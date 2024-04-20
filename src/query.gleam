import query/select_query.{type SelectQuery}
import query/union_query.{type UnionQuery}

pub type Query {
  SelectQuery(SelectQuery)
  UnionQuery(UnionQuery)
}
