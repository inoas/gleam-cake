import adapters/generic
import query/select_query.{type SelectQuery}

pub fn to_sql(query: SelectQuery) {
  query
  |> generic.to_sql
}
