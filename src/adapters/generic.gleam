import extlib/stringx
import fragment/order_by_direction
import fragment/where
import gleam/int
import gleam/list
import gleam/string
import query/select_query.{type SelectQuery}
import sqlight

pub fn to_sql(query: SelectQuery) {
  query
  |> build_select_sql
  |> maybe_add_where_sql(query)
  |> maybe_add_where_strings_sql(query)
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
    _ -> {
      let where_sql =
        query.where
        |> stringx.map_join(
          // TODO: use to_prepared_sql here
          map: fn(where) { where.to_sql(where) },
          join: " AND ",
        )
      query_string <> " WHERE " <> where_sql
    }
  }
}

fn maybe_add_where_strings_sql(query_string: String, query: SelectQuery) {
  case query.where_strings, query.where {
    [], _ -> query_string
    _, [] ->
      query_string <> " WHERE " <> string.join(query.where_strings, " AND ")
    _, _ -> query_string <> " AND " <> string.join(query.where_strings, " AND ")
  }
}

fn maybe_add_order_sql(query_string: String, query: SelectQuery) {
  case query.order_by {
    [] -> query_string
    _ -> {
      let order_bys =
        query.order_by
        |> list.map(fn(order_by) {
          order_by.0 <> " " <> order_by_direction.to_sql(order_by.1)
        })

      query_string <> " ORDER BY " <> string.join(order_bys, ", ")
    }
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
