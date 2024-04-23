import cake/fragment/order_by_direction
import cake/fragment/where.{type WhereFragment}
import cake/query/select.{type SelectQuery}
import cake/types.{type PreparedStatement}
import gleam/int
import gleam/list
import gleam/string

// import pprint.{debug as dbg}

pub fn build_select_prepared_statement(
  select_query sq: SelectQuery,
  prepared_symbol prpsmbl: String,
) -> PreparedStatement {
  let prep_stm = #("", [])

  prep_stm
  |> apply_to_query(maybe_add_select_sql, sq)
  |> apply_to_query(maybe_add_from_sql, sq)
  |> maybe_add_where(sq, prpsmbl)
  |> apply_to_query(maybe_add_where_strings_sql, sq)
  |> apply_to_query(maybe_add_order_sql, sq)
  |> apply_to_query(maybe_add_limit_sql, sq)
  |> apply_to_query(maybe_add_offset_sql, sq)
}

fn maybe_add_where(
  prepared_statement prep_stm: PreparedStatement,
  query qry: SelectQuery,
  prepared_symbol prepsym: String,
) -> PreparedStatement {
  case qry.where {
    [] -> prep_stm
    _ -> {
      let #(new_query, new_params) =
        qry.where
        |> list.fold(#("", []), fn(acc: PreparedStatement, item: WhereFragment) {
          let #(query, params) = where.to_prepared_sql(item, prepsym)
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
  query_string qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.where_strings, qry.where {
    [], _ -> qs
    _, [] -> qs <> " WHERE " <> string.join(qry.where_strings, " AND ")
    _, _ -> qs <> " AND " <> string.join(qry.where_strings, " AND ")
  }
}

fn apply_to_query(prep_stm: PreparedStatement, fun, query) -> PreparedStatement {
  #(fun(prep_stm.0, query), prep_stm.1)
}

fn maybe_add_select_sql(
  query_string qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.select {
    [] -> qs <> "SELECT *"
    _ -> qs <> "SELECT " <> string.join(qry.select, ", ")
  }
}

fn maybe_add_from_sql(query_string qs: String, query qry: SelectQuery) -> String {
  qs <> " FROM " <> qry.from
}

fn maybe_add_order_sql(
  query_string qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.order_by {
    [] -> qs
    _ -> {
      let order_bys =
        qry.order_by
        |> list.map(fn(order_by) {
          order_by.0 <> " " <> order_by_direction.to_sql(order_by.1)
        })

      qs <> " ORDER BY " <> string.join(order_bys, ", ")
    }
  }
}

fn maybe_add_limit_sql(
  query_string qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.limit < 0 {
    True -> qs
    False -> qs <> " LIMIT " <> int.to_string(qry.limit)
  }
}

fn maybe_add_offset_sql(
  query_string qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.offset < 0 {
    True -> qs
    False -> qs <> " OFFSET " <> int.to_string(qry.offset)
  }
}
