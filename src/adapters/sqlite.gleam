import adapters/generic
import pprint
import query/select_query.{type SelectQuery}
import sqlight

pub fn to_sql(query: SelectQuery) {
  query
  |> generic.to_sql
}

pub fn execute(conn, query, decoder) {
  query
  |> to_sql
  |> pprint.debug
  |> sqlight.query(on: conn, with: [], expecting: decoder)
}
