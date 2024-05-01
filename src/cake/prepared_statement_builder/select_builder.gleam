import cake/internal/query.{type OrderByPart, type SelectQuery}
import cake/prepared_statement.{type PreparedStatement}

// import cake/stdlib/iox
import cake/stdlib/stringx
import gleam/list
import gleam/string

pub fn build(
  select sq: SelectQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  prp_stm_prfx |> prepared_statement.new() |> apply_sql(sq)
}

pub fn apply_sql(
  prepared_statement prp_stm: PreparedStatement,
  select sq: SelectQuery,
) -> PreparedStatement {
  prp_stm
  |> apply_to_sql(maybe_add_select_sql, sq)
  |> apply_to_sql(maybe_add_from_sql, sq)
  |> maybe_add_join(sq)
  |> maybe_add_where(sq)
  |> apply_to_sql(maybe_add_order_sql, sq)
  |> maybe_add_limit_offset(sq)
}

fn apply_to_sql(
  prp_stm: PreparedStatement,
  maybe_add_fun: fn(SelectQuery) -> String,
  qry: SelectQuery,
) -> PreparedStatement {
  prepared_statement.with_sql(prp_stm, maybe_add_fun(qry))
}

fn maybe_add_select_sql(query qry: SelectQuery) -> String {
  case qry.select {
    [] -> "SELECT *"
    _ ->
      "SELECT " <> stringx.map_join(qry.select, query.select_part_to_sql, ", ")
  }
}

fn maybe_add_from_sql(query qry: SelectQuery) -> String {
  query.from_part_to_sql(qry.from)
}

fn maybe_add_where(
  prepared_statement prp_stm: PreparedStatement,
  query qry: SelectQuery,
) -> PreparedStatement {
  query.where_part_append_to_prepared_statement_as_clause(qry.where, prp_stm)
}

fn maybe_add_join(
  prepared_statement prp_stm: PreparedStatement,
  query qry: SelectQuery,
) -> PreparedStatement {
  query.join_parts_append_to_prepared_statement_as_clause(qry.join, prp_stm)
}

fn maybe_add_order_sql(query qry: SelectQuery) -> String {
  case qry.order_by {
    [] -> ""
    _ -> {
      let order_bys =
        qry.order_by
        |> list.map(fn(ordrb: OrderByPart) -> String {
          ordrb.column <> " " <> query.order_by_part_to_sql(ordrb)
        })

      " ORDER BY " <> string.join(order_bys, ", ")
    }
  }
}

fn maybe_add_limit_offset(
  prepared_statement prp_stm: PreparedStatement,
  select_query slct_qry: SelectQuery,
) -> PreparedStatement {
  let lmt_offst = query.limit_offset_get(slct_qry)
  // |> iox.dbg_label("lmt_offst")

  prp_stm
  |> query.limit_offset_apply(lmt_offst)
}
