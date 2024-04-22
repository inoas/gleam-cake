import cake/fragment/order_by_direction
import cake/fragment/where.{type WhereFragment}
import cake/query/select.{type SelectQuery}
import cake/types.{type PreparedStatement}
import gleam/int
import gleam/list
import gleam/string

// import pprint.{debug as dbg}

pub fn build_select_prepared_statement(sq: SelectQuery) -> PreparedStatement {
  let prep_stm = #("", [])

  prep_stm
  |> apply_to_query(maybe_add_select_sql, sq)
  |> apply_to_query(maybe_add_from_sql, sq)
  |> maybe_add_where(sq)
  |> apply_to_query(maybe_add_where_strings_sql, sq)
  |> apply_to_query(maybe_add_order_sql, sq)
  |> apply_to_query(maybe_add_limit_sql, sq)
  |> apply_to_query(maybe_add_offset_sql, sq)
}

fn maybe_add_where(
  prep_stm: PreparedStatement,
  query: SelectQuery,
) -> PreparedStatement {
  case query.where {
    [] -> prep_stm
    _ -> {
      let #(new_query, new_params) =
        query.where
        |> list.fold(#("", []), fn(acc: PreparedStatement, item: WhereFragment) {
          let #(query, params) = where.to_prepared_sql(item)
          let new_query = case acc.0 {
            "" -> " WHERE " <> query
            _ -> acc.0 <> " AND " <> query
          }
          let new_params = list.append(acc.1, params)
          #(new_query, new_params)
        })

      #(prep_stm.0 <> new_query, list.append(prep_stm.1, new_params))
    }
  }
}

fn maybe_add_where_strings_sql(
  query_string: String,
  query: SelectQuery,
) -> String {
  case query.where_strings, query.where {
    [], _ -> query_string
    _, [] ->
      query_string <> " WHERE " <> string.join(query.where_strings, " AND ")
    _, _ -> query_string <> " AND " <> string.join(query.where_strings, " AND ")
  }
}

fn apply_to_query(prep_stm: PreparedStatement, fun, query) -> PreparedStatement {
  #(fun(prep_stm.0, query), prep_stm.1)
}

fn maybe_add_select_sql(query_string: String, query: SelectQuery) -> String {
  case query.select {
    [] -> query_string <> "SELECT *"
    _ -> query_string <> "SELECT " <> string.join(query.select, ", ")
  }
}

fn maybe_add_from_sql(query_string: String, query: SelectQuery) -> String {
  query_string <> " FROM " <> query.from
}

fn maybe_add_order_sql(query_string: String, query: SelectQuery) -> String {
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

fn maybe_add_limit_sql(query_string: String, query: SelectQuery) -> String {
  case query.limit < 0 {
    True -> query_string
    False -> query_string <> " LIMIT " <> int.to_string(query.limit)
  }
}

fn maybe_add_offset_sql(query_string: String, query: SelectQuery) -> String {
  case query.offset < 0 {
    True -> query_string
    False -> query_string <> " OFFSET " <> int.to_string(query.offset)
  }
}
