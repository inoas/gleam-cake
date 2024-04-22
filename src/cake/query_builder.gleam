import cake/fragment/order_by_direction
import cake/fragment/where
import cake/query/select.{type SelectQuery}
import cake/stdlib/stringx
import gleam/int
import gleam/list
import gleam/string

pub fn build_select_sql(sq: SelectQuery) -> String {
  let qry = "SELECT " <> string.join(sq.select, ", ") <> " FROM " <> sq.from

  qry
  |> maybe_add_where_sql(sq)
  |> maybe_add_where_strings_sql(sq)
  |> maybe_add_order_sql(sq)
  |> maybe_add_limit_sql(sq)
  |> maybe_add_offset_sql(sq)
}

fn maybe_add_where_sql(query_string: String, query: SelectQuery) {
  case query.where {
    [] -> query_string
    _ -> {
      let where_sql =
        query.where
        |> stringx.map_join(
          // TODO: use to_prepared_sql here
          map: fn(where) { where.to_debug_sql(where) },
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
