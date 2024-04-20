import gleam/int
import gleam/string
import query/select_query.{type SelectQuery}

pub fn to_sql(query: SelectQuery) {
  query
  |> build_select_sql
  |> maybe_add_where_sql(query)
  |> maybe_add_order_sql(query)
  |> maybe_add_limit_sql(query)
  |> maybe_add_offset_sql(query)
}

fn build_select_sql(query: SelectQuery) {
  "SELECT " <> string.join(query.select, ", ") <> " FROM " <> query.from
}

fn maybe_add_where_sql(query_string: String, query: SelectQuery) {
  case query.where {
    [] -> query_string
    _ -> query_string <> " WHERE " <> string.join(query.where, " AND ")
  }
}

fn maybe_add_order_sql(query_string: String, query: SelectQuery) {
  case query.order {
    [] -> query_string
    _ -> query_string <> " ORDER BY " <> string.join(query.order, ", ")
  }
}

fn maybe_add_limit_sql(query_string: String, query: SelectQuery) {
  case query.limit < 0 {
    True -> query_string
    False -> query_string <> " LIMIT " <> int.to_string(query.limit)
  }
}

fn maybe_add_offset_sql(query_string: String, query: SelectQuery) {
  case query.offset < 0 {
    True -> query_string
    False -> query_string <> " OFFSET " <> int.to_string(query.offset)
  }
}
