import cake/internal/query.{
  type CombinedQuery, type SelectQuery, Except, ExceptAll, Intersect,
  IntersectAll, Union, UnionAll,
}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder

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
  prp_stm_prfx |> prepared_statement.new() |> apply_sql(cq)
}

pub fn apply_sql(
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
  |> query.limit_offset_apply(cq.limit_offset)
  |> query.epilog_apply(cq.epilog)
}
