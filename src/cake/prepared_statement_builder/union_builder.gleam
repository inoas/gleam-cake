import cake/internal/query.{type SelectQuery, type UnionQuery}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder

// import cake/stdlib/iox
import gleam/list

pub fn build(
  select uq: UnionQuery,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new()
  |> apply_sql(uq)
}

pub fn apply_sql(
  prepared_statement prp_stm: PreparedStatement,
  select uq: UnionQuery,
) -> PreparedStatement {
  query.union_get_select_queries(uq)
  |> list.fold(
    prp_stm,
    fn(acc: PreparedStatement, sq: SelectQuery) -> PreparedStatement {
      case acc == prp_stm {
        True -> {
          acc
          |> select_builder.apply_sql(sq)
        }
        False -> {
          acc
          |> prepared_statement.with_sql(" UNION ")
          |> select_builder.apply_sql(sq)
        }
      }
    },
  )
}
