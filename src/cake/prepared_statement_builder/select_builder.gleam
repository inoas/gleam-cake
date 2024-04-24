import cake/internal/query.{type SelectQuery}
import cake/prepared_statement.{type PreparedStatement}
import cake/stdlib/stringx

// import cake/stdlib/iox
import gleam/int
import gleam/list
import gleam/string

pub fn build(
  select sq: SelectQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new()
  |> apply_sql(sq)
}

pub fn apply_sql(
  prepared_statement prp_stm: PreparedStatement,
  select sq: SelectQuery,
) -> PreparedStatement {
  prp_stm
  |> apply_to_sql(maybe_add_select_sql, sq)
  |> apply_to_sql(maybe_add_from_sql, sq)
  |> maybe_add_where(sq)
  |> apply_to_sql(maybe_add_order_sql, sq)
  |> apply_to_sql(maybe_add_limit_sql, sq)
  |> apply_to_sql(maybe_add_offset_sql, sq)
}

fn apply_to_sql(
  prp_stm: PreparedStatement,
  maybe_add_fun: fn(SelectQuery) -> String,
  qry: SelectQuery,
) -> PreparedStatement {
  prepared_statement.with_sql(prp_stm, maybe_add_fun(qry))
}

fn maybe_add_where(
  prepared_statement prp_stm: PreparedStatement,
  query qry: SelectQuery,
) -> PreparedStatement {
  query.where_fragment_append_to_prepared_statement_as_clause(
    qry.where,
    prp_stm,
  )
}

fn maybe_add_select_sql(query qry: SelectQuery) -> String {
  case qry.select {
    [] -> "SELECT *"
    _ ->
      "SELECT "
      <> stringx.map_join(qry.select, query.select_fragment_to_sql, ", ")
  }
}

fn maybe_add_from_sql(query qry: SelectQuery) -> String {
  query.from_fragment_to_sql(qry.from)
}

fn maybe_add_order_sql(query qry: SelectQuery) -> String {
  case qry.order_by {
    [] -> ""
    _ -> {
      let order_bys =
        qry.order_by
        |> list.map(fn(order_by) {
          order_by.0
          <> " "
          <> query.order_by_direction_fragment_to_sql(order_by.1)
        })

      " ORDER BY " <> string.join(order_bys, ", ")
    }
  }
}

fn maybe_add_limit_sql(query qry: SelectQuery) -> String {
  case qry.limit < 0 {
    True -> ""
    False -> " LIMIT " <> int.to_string(qry.limit)
  }
}

fn maybe_add_offset_sql(query qry: SelectQuery) -> String {
  case qry.offset < 0 {
    True -> ""
    False -> " OFFSET " <> int.to_string(qry.offset)
  }
}
