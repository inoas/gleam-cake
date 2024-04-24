import cake/prepared_statement.{type PreparedStatement}

// import cake/stdlib/iox
import cake/param.{type Param, NullParam}

// import cake/query.{type Query}
import gleam/list

pub type WhereFragment {
  // Column A to column B comparison
  WhereColEqualCol(a_column: String, b_column: String)
  WhereColLowerCol(a_column: String, b_column: String)
  WhereColLowerOrEqualCol(a_column: String, b_column: String)
  WhereColGreaterCol(a_column: String, b_column: String)
  WhereColGreaterOrEqualCol(a_column: String, b_column: String)
  WhereColNotEqualCol(a_column: String, b_column: String)
  // Column to parameter comparison
  WhereColEqualParam(column: String, parameter: Param)
  WhereColLowerParam(column: String, parameter: Param)
  WhereColLowerOrEqualParam(column: String, parameter: Param)
  WhereColGreaterParam(column: String, parameter: Param)
  WhereColGreaterOrEqualParam(column: String, parameter: Param)
  WhereColNotEqualParam(column: String, parameter: Param)
  // Parameter to column comparison
  WhereParamEqualCol(parameter: Param, column: String)
  WhereParamLowerCol(parameter: Param, column: String)
  WhereParamLowerOrEqualCol(parameter: Param, column: String)
  WhereParamGreaterCol(parameter: Param, column: String)
  WhereParamGreaterOrEqualCol(parameter: Param, column: String)
  WhereParamNotEqualCol(parameter: Param, column: String)
  // Logical operators
  AndWhere(fragments: List(WhereFragment))
  NotWhere(fragments: List(WhereFragment))
  OrWhere(fragments: List(WhereFragment))
  // XorWhere(List(WhereFragment))
  // Subquery
  // WhereColEqualSubquery(column: String, sub_query: Query)
  // WhereColLowerSubquery(column: String, sub_query: Query)
  // WhereColLowerOrEqualSubquery(column: String, sub_query: Query)
  // WhereColGreaterSubquery(column: String, sub_query: Query)
  // WhereColGreaterOrEqualSubquery(column: String, sub_query: Query)
  // WhereColNotEqualSubquery(column: String, sub_query: Query)
  // Column contains value
  WhereColInParams(column: String, parameters: List(Param))
  // WhereColInSubquery(column: String, sub_query: Query)
  NoWhereFragment
}

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
fn append_to_prepared_statement(
  prepared_statement prp_stm: PreparedStatement,
  fragment frgmt: WhereFragment,
) -> PreparedStatement {
  case frgmt {
    WhereColEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "=", b_col)
    WhereColLowerCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<", b_col)
    WhereColLowerOrEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<=", b_col)
    WhereColGreaterCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, ">", b_col)
    WhereColGreaterOrEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, ">=", b_col)
    WhereColNotEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<>", b_col)
    WhereColEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    WhereColEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "=", param)
    WhereColLowerParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<", param)
    WhereColLowerOrEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<=", param)
    WhereColGreaterParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, ">", param)
    WhereColGreaterOrEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, ">=", param)
    WhereColNotEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereColNotEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<>", param)
    WhereParamEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    WhereParamEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "=", col)
    WhereParamLowerCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<", col)
    WhereParamLowerOrEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<=", col)
    WhereParamGreaterCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, ">", col)
    WhereParamGreaterOrEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, ">=", col)
    WhereParamNotEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereParamNotEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<>", col)
    AndWhere(frgmts) -> apply_logical_sql_operator("AND", frgmts, prp_stm)
    NotWhere(frgmts) -> apply_logical_sql_operator("NOT", frgmts, prp_stm)
    OrWhere(frgmts) -> apply_logical_sql_operator("OR", frgmts, prp_stm)
    WhereColInParams(col, params) ->
      apply_column_in_params(col, params, prp_stm)
    NoWhereFragment -> prp_stm
  }
}

pub fn append_to_prepared_statement_as_clause(
  fragment frgmt: WhereFragment,
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  case frgmt {
    NoWhereFragment -> prp_stm
    _ -> {
      prp_stm
      |> prepared_statement.with_sql(" WHERE ")
      |> append_to_prepared_statement(frgmt)
    }
  }
}

fn apply_comparison_col_col(prp_stm, a_col, sql_operator, b_col) {
  prepared_statement.with_sql(
    prp_stm,
    a_col <> " " <> sql_operator <> " " <> b_col,
  )
}

fn apply_comparison_col_param(prp_stm, col, sql_operator, param) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    col <> " " <> sql_operator <> " " <> next_param,
    param,
  )
}

fn apply_comparison_param_col(prp_stm, param, sql_operator, col) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    next_param <> " " <> sql_operator <> " " <> col,
    param,
  )
}

fn apply_logical_sql_operator(
  operator oprtr: String,
  fragments frgmts: List(WhereFragment),
  prepared_statement prp_stm: PreparedStatement,
) {
  let new_prep_stm =
    prp_stm
    |> prepared_statement.with_sql("(")

  let new_prep_stm =
    list.fold(
      frgmts,
      new_prep_stm,
      fn(acc: PreparedStatement, frgmt: WhereFragment) -> PreparedStatement {
        case acc == new_prep_stm {
          True ->
            acc
            |> append_to_prepared_statement(frgmt)
          False ->
            acc
            |> prepared_statement.with_sql(" " <> oprtr <> " ")
            |> append_to_prepared_statement(frgmt)
        }
      },
    )

  new_prep_stm
  |> prepared_statement.with_sql(")")
}

fn apply_column_in_params(
  column col: String,
  parameters params: List(Param),
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  let new_prep_stm =
    prp_stm
    |> prepared_statement.with_sql(col <> " IN (")

  let new_prep_stm =
    list.fold(
      params,
      new_prep_stm,
      fn(acc: PreparedStatement, param: Param) -> PreparedStatement {
        let new_sql = case acc == new_prep_stm {
          True -> prepared_statement.next_param(prp_stm)
          False -> ", " <> prepared_statement.next_param(acc)
        }
        prepared_statement.with_sql_and_param(acc, new_sql, param)
      },
    )

  new_prep_stm
  |> prepared_statement.with_sql(")")
}

pub fn to_debug(
  fragment frgmt: WhereFragment,
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  prp_stm
  |> append_to_prepared_statement(frgmt)
}
