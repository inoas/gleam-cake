import adapters/generic
import pprint.{debug as dbg}
import query/select_query.{type SelectQuery}
import sqlight

pub fn to_sql(query: SelectQuery) {
  query
  |> generic.to_sql
}

pub fn execute(conn, query, decoder) {
  query
  |> to_sql
  |> dbg
  |> sqlight.query(on: conn, with: [], expecting: decoder)
}
