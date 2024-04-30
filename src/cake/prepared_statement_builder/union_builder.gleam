import cake/internal/query.{
  type CombinedQuery, type OrderByPart, type SelectQuery, Except, ExceptAll,
  Intersect, IntersectAll, Union, UnionAll,
}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder
import gleam/string

// import cake/stdlib/iox
import gleam/list

pub fn build(
  select cq: CombinedQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  // TODO: what happens if multiple select queries have different type signatures for their columns?
  // -> In prepared statements we can already check this and return either an OK() or an Error()
  // The error would return that the column types missmatch
  // The user probably let assets this then?
  prp_stm_prfx
  |> prepared_statement.new()
  |> apply_command_sql(cq)
  |> apply_to_sql(maybe_add_order_sql, cq)
  |> query.limit_offset_apply(cq.limit_offset)
  |> query.epilog_apply(cq.epilog)
}

pub fn apply_command_sql(
  prepared_statement prp_stm: PreparedStatement,
  select cq: CombinedQuery,
) -> PreparedStatement {
  let combination = case cq.kind {
    Union -> "UNION"
    UnionAll -> "UNION ALL"
    Except -> "EXCEPT"
    ExceptAll -> "EXCEPT ALL"
    Intersect -> "INTERSECT"
    IntersectAll -> "INTERSECT ALL"
  }

  cq.select_queries
  |> list.fold(
    prp_stm,
    fn(acc: PreparedStatement, sq: SelectQuery) -> PreparedStatement {
      case acc == prp_stm {
        True -> acc |> select_builder.apply_sql(sq)
        False -> {
          acc
          |> prepared_statement.with_sql(" " <> combination <> " ")
          |> select_builder.apply_sql(sq)
        }
      }
    },
  )
}

fn apply_to_sql(
  prp_stm: PreparedStatement,
  maybe_add_fun: fn(CombinedQuery) -> String,
  qry: CombinedQuery,
) -> PreparedStatement {
  prepared_statement.with_sql(prp_stm, maybe_add_fun(qry))
}

fn maybe_add_order_sql(query qry: CombinedQuery) -> String {
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
