import cake/internal/query.{type Query, Select, Union}
import cake/prepared_statement.{type PreparedStatement}
import cake/prepared_statement_builder/select_builder
import cake/prepared_statement_builder/union_builder

pub fn build(
  query qry: Query,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  case qry {
    Select(qry) -> select_builder.build(qry, prp_stm_prfx)
    Union(qry) -> union_builder.build(qry, prp_stm_prfx)
  }
}
