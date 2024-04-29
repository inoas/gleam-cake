import cake/internal/query.{
  type SelectQuery, type UnionQuery, UnionAll, UnionDistinct, UnionExcept,
  UnionIntersect,
}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder

// import cake/stdlib/iox
import gleam/list

pub fn build(
  select uq: UnionQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  // TODO: what happens if multiple select queries have different type signatures for their columns?
  // -> In prepared statements we can already check this and return either an OK() or an Error()
  // The error would return that the column types missmatch
  // The user probably let assets this then?
  prp_stm_prfx |> prepared_statement.new() |> apply_sql(uq)
}

pub fn apply_sql(
  prepared_statement prp_stm: PreparedStatement,
  select uq: UnionQuery,
) -> PreparedStatement {
  let union_keyword = case uq.union_kind {
    UnionAll -> "UNION ALL"
    UnionDistinct -> "UNION"
    UnionExcept -> "EXCEPT"
    UnionIntersect -> "INTERSECT"
  }

  uq.select_queries
  |> list.fold(
    prp_stm,
    fn(acc: PreparedStatement, sq: SelectQuery) -> PreparedStatement {
      case acc == prp_stm {
        True -> acc |> select_builder.apply_sql(sq)
        False -> {
          acc
          |> prepared_statement.with_sql(" " <> union_keyword <> " ")
          |> select_builder.apply_sql(sq)
        }
      }
    },
  )
  |> query.limit_offset_apply(uq.limit_offset)
  |> query.epilog_apply(uq.epilog)
}
