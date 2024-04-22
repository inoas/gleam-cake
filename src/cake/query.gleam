import cake/query/select.{type SelectQuery}
import cake/query/union.{type UnionQuery}

pub type Query {
  SelectQuery(SelectQuery)
  UnionQuery(UnionQuery)
}
