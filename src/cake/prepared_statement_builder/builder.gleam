import cake/internal/query.{type Query, Combined, Select}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder
import cake/prepared_statement_builder/union_builder

pub fn build(
  query qry: Query,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  case qry {
    Select(query: qry) -> qry |> select_builder.build(prp_stm_prfx)
    Combined(query: qry) -> qry |> union_builder.build(prp_stm_prfx)
  }
}
