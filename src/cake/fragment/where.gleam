import cake/prepared_statement.{type PreparedStatement}

// import cake/stdlib/iox
import cake/types.{type Param, NullParam}
import gleam/list

pub type WhereFragment {
  // Column A to column B comparison
  ColEqualCol(a_column: String, b_column: String)
  ColLowerCol(a_column: String, b_column: String)
  ColLowerOrEqualCol(a_column: String, b_column: String)
  ColGreaterCol(a_column: String, b_column: String)
  ColGreaterOrEqualCol(a_column: String, b_column: String)
  ColNotEqualCol(a_column: String, b_column: String)
  // Column to parameter comparison
  ColEqualParam(column: String, parameter: Param)
  ColLowerParam(column: String, parameter: Param)
  ColLowerOrEqualParam(column: String, parameter: Param)
  ColGreaterParam(column: String, parameter: Param)
  ColGreaterOrEqualParam(column: String, parameter: Param)
  ColNotEqualParam(column: String, parameter: Param)
  // Parameter to column comparison
  ParamEqualCol(parameter: Param, column: String)
  ParamLowerCol(parameter: Param, column: String)
  ParamLowerOrEqualCol(parameter: Param, column: String)
  ParamGreaterCol(parameter: Param, column: String)
  ParamGreaterOrEqualCol(parameter: Param, column: String)
  ParamNotEqualCol(parameter: Param, column: String)
  // Logical operators
  AndWhere(fragments: List(WhereFragment))
  NotWhere(fragments: List(WhereFragment))
  OrWhere(fragments: List(WhereFragment))
  // XorWhere(List(WhereFragment))
  // Column contains value
  ColInParams(column: String, parameters: List(Param))
  NoWhereFragment
}

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
fn append_to_prepared_statement(
  prepared_statement prp_stm: PreparedStatement,
  fragment frgmt: WhereFragment,
) -> PreparedStatement {
  case frgmt {
    ColEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "=", b_col)
    ColLowerCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<", b_col)
    ColLowerOrEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<=", b_col)
    ColGreaterCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, ">", b_col)
    ColGreaterOrEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, ">=", b_col)
    ColNotEqualCol(a_col, b_col) ->
      apply_comparison_col_col(prp_stm, a_col, "<>", b_col)
    ColEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    ColEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "=", param)
    ColLowerParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<", param)
    ColLowerOrEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<=", param)
    ColGreaterParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, ">", param)
    ColGreaterOrEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, ">=", param)
    ColNotEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    ColNotEqualParam(col, param) ->
      apply_comparison_col_param(prp_stm, col, "<>", param)
    ParamEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    ParamEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "=", col)
    ParamLowerCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<", col)
    ParamLowerOrEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<=", col)
    ParamGreaterCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, ">", col)
    ParamGreaterOrEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, ">=", col)
    ParamNotEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    ParamNotEqualCol(param, col) ->
      apply_comparison_param_col(prp_stm, param, "<>", col)
    AndWhere(frgmts) -> apply_logical_sql_operator("AND", frgmts, prp_stm)
    NotWhere(frgmts) -> apply_logical_sql_operator("NOT", frgmts, prp_stm)
    OrWhere(frgmts) -> apply_logical_sql_operator("OR", frgmts, prp_stm)
    ColInParams(col, params) -> apply_column_in_params(col, params, prp_stm)
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
