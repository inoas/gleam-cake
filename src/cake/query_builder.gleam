import cake/fragment/from
import cake/fragment/order_by_direction
import cake/fragment/select as sf
import cake/fragment/where
import cake/prepared_statement.{type PreparedStatement}
import cake/query/select.{type SelectQuery}
import cake/stdlib/stringx

// import cake/stdlib/iox
import gleam/int
import gleam/list
import gleam/string

pub fn build_select_prepared_statement(
  select_query sq: SelectQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  let prp_stm = prepared_statement.new(prp_stm_prfx)

  prp_stm
  |> apply_to_sql(maybe_add_select_sql, sq)
  |> apply_to_sql(maybe_add_from_sql, sq)
  |> maybe_add_where(sq)
  |> apply_to_sql(maybe_add_order_sql, sq)
  |> apply_to_sql(maybe_add_limit_sql, sq)
  |> apply_to_sql(maybe_add_offset_sql, sq)
}

fn apply_to_sql(prp_stm: PreparedStatement, f, qry) -> PreparedStatement {
  let sql = prepared_statement.get_sql(prp_stm)
  prepared_statement.with_sql(prp_stm, f(sql, qry))
}

fn maybe_add_where(
  prepared_statement prp_stm: PreparedStatement,
  query qry: SelectQuery,
) -> PreparedStatement {
  where.append_to_prepared_statement_as_clause(qry.where, prp_stm)
}

fn maybe_add_select_sql(
  query_string _qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.select {
    [] -> "SELECT *"
    _ -> "SELECT " <> stringx.map_join(qry.select, sf.to_sql, " ,")
  }
}

fn maybe_add_from_sql(
  query_string _qs: String,
  query qry: SelectQuery,
) -> String {
  from.to_sql(qry.from)
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

      " ORDER BY " <> string.join(order_bys, ", ")
    }
  }
}

fn maybe_add_limit_sql(
  query_string _qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.limit < 0 {
    True -> ""
    False -> " LIMIT " <> int.to_string(qry.limit)
  }
}

fn maybe_add_offset_sql(
  query_string _qs: String,
  query qry: SelectQuery,
) -> String {
  case qry.offset < 0 {
    True -> ""
    False -> " OFFSET " <> int.to_string(qry.offset)
  }
}
