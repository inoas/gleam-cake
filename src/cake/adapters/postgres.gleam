import cake/adapters/generic
import cake/query/select.{type SelectQuery}

pub fn to_sql(query: SelectQuery) {
  query
  |> generic.to_sql
}
