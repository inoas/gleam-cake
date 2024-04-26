// —————————————————————————————————————————————————————————————————————————— //
// ———— Query ——————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type Query {
  Select(SelectQuery)
  Union(UnionQuery)
}

pub fn query_select_wrap(qry: SelectQuery) -> Query {
  Select(qry)
}

pub fn query_union_wrap(qry: UnionQuery) -> Query {
  Union(qry)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SelectQuery ————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

// List of SQL parts that will be used to build a select query.
pub type SelectQuery {
  SelectQuery(
    from: FromFragment,
    // comment: String,
    // modifier: String,
    // with: String,
    select: List(SelectFragment),
    // distinct: String,
    // join: String,
    where: WhereFragment,
    // group_by: String,
    // having: String,
    // window: String,
    order_by: List(#(String, OrderByDirectionFragment)),
    limit: Int,
    offset: Int,
    // epilog: String,
    flags: List(#(String, String)),
  )
}

// ———— NEW ————————————————————————————————————————————————————————————————— //

pub fn select_query_new(
  from from: FromFragment,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(
    from: from,
    select: select,
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn select_query_new_from(from from: FromFragment) -> SelectQuery {
  SelectQuery(
    from: from,
    select: [],
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn select_query_new_select(
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(
    from: NoFromFragment,
    select: select,
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

// ———— FROM ———————————————————————————————————————————————————————————————— //

pub fn select_query_set_from(
  query qry: SelectQuery,
  from from: FromFragment,
) -> SelectQuery {
  SelectQuery(..qry, from: from)
}

// ———— SELECT —————————————————————————————————————————————————————————————— //

pub fn select_query_select(
  query qry: SelectQuery,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, select))
}

pub fn select_query_select_replace(
  query qry: SelectQuery,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(..qry, select: select)
}

// ———— WHERE ——————————————————————————————————————————————————————————————— //

pub fn select_query_set_where(
  query qry: SelectQuery,
  where where: WhereFragment,
) -> SelectQuery {
  SelectQuery(..qry, where: where)
}

// ———— ORDER BY ———————————————————————————————————————————————————————————— //

pub fn select_query_order_asc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, Asc), True)
}

pub fn select_query_order_asc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, AscNullsFirst), True)
}

pub fn select_query_order_asc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, Asc), False)
}

pub fn select_query_order_asc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, AscNullsFirst), False)
}

pub fn select_query_order_desc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, Desc), True)
}

pub fn select_query_order_desc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, DescNullsFirst), True)
}

pub fn select_query_order_desc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, Desc), False)
}

pub fn select_query_order_desc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, DescNullsFirst), False)
}

pub fn select_query_order(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionFragment,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), True)
}

pub fn select_query_order_replace(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionFragment,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), False)
}

fn do_order_by(
  query qry: SelectQuery,
  by ordb: #(String, OrderByDirectionFragment),
  append append: Bool,
) -> SelectQuery {
  case append {
    True -> SelectQuery(..qry, order_by: list.append(qry.order_by, [ordb]))
    False -> SelectQuery(..qry, order_by: [ordb])
  }
}

// ———— LIMIT & OFFSET —————————————————————————————————————————————————————— //

pub fn select_query_set_limit(qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  case lmt >= 0 {
    True -> SelectQuery(..qry, limit: lmt)
    // TODO: Add warning, negative limit is ignored
    False -> SelectQuery(..qry, limit: -1)
  }
}

pub fn select_query_set_limit_and_offset(
  query qry: SelectQuery,
  limit lmt: Int,
  offset offst: Int,
) -> SelectQuery {
  case lmt >= 0, offst >= 0 {
    True, True -> SelectQuery(..qry, limit: lmt, offset: offst)
    // TODO: Add debug warning, negative limit is ignored as well as any offset then
    True, False -> SelectQuery(..qry, limit: lmt, offset: -1)
    // TODO: Add debug negative offset is ignored
    False, _ -> SelectQuery(..qry, limit: -1, offset: -1)
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— UnionQuery —————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

// List of SQL parts that will be used to build a union query.
pub opaque type UnionQuery {
  UnionDistinctQuery(select_queries: List(SelectQuery))
  UnionAllQuery(select_queries: List(SelectQuery))
  // TODO: also takes order_by, limit, offset
  // TODO: order_by of contained selects must be stripped
}

pub fn union_distinct_query_new(
  select_queries select_queries: List(SelectQuery),
) -> UnionQuery {
  UnionDistinctQuery(select_queries: select_queries)
}

pub fn union_all_query_new(
  select_queries select_queries: List(SelectQuery),
) -> UnionQuery {
  UnionAllQuery(select_queries: select_queries)
}

pub fn union_get_select_queries(union_query uq: UnionQuery) -> List(SelectQuery) {
  case uq {
    UnionDistinctQuery(select_queries) -> select_queries
    UnionAllQuery(select_queries) -> select_queries
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— FromFragment ———————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type FromFragment {
  FromString(String)
  // TODO: check if the table does indeed exist
  FromTable(String)
  NoFromFragment
}

pub fn from_fragment_from_table(s: String) -> FromFragment {
  FromTable(s)
}

pub fn from_fragment_to_sql(fragment frgmt: FromFragment) {
  case frgmt {
    FromString(s) -> " FROM " <> s
    FromTable(s) -> " FROM " <> s
    NoFromFragment -> ""
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— OrderByDirectionFragment ———————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type OrderByDirectionFragment {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn order_by_direction_fragment_to_sql(
  fragment frgmt: OrderByDirectionFragment,
) {
  case frgmt {
    Asc -> " ASC NULLS LAST"
    Desc -> " DESC NULLS LAST"
    AscNullsFirst -> " ASC NULLS FIRST"
    DescNullsFirst -> " DESC NULLS FIRST"
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SelectFragment —————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type SelectFragment {
  // Strings are arbitrary SQL strings
  // Aliases rename fields
  SelectString(string: String)
  SelectStringAlias(string: String, alias: String)
  // Columns are:
  // - auto prefixed? by their corresponding tables if not given
  // - checked if they exist
  SelectColumn(column: String)
  SelectColumnAlias(column: String, alias: String)
}

pub fn select_fragment_from_string(s: String) -> SelectFragment {
  // TODO: check if the table does indeed exist
  SelectString(s)
}

pub fn select_fragment_to_sql(fragment frgmt: SelectFragment) {
  case frgmt {
    SelectString(string) -> string
    SelectStringAlias(string, alias) -> string <> " AS " <> alias
    SelectColumn(column) -> column
    SelectColumnAlias(column, alias) -> column <> " AS " <> alias
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— WhereFragment ——————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

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
fn where_fragment_append_to_prepared_statement(
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
      where_fragment_apply_comparison_col_param(prp_stm, col, "=", param)
    WhereColLowerParam(col, param) ->
      where_fragment_apply_comparison_col_param(prp_stm, col, "<", param)
    WhereColLowerOrEqualParam(col, param) ->
      where_fragment_apply_comparison_col_param(prp_stm, col, "<=", param)
    WhereColGreaterParam(col, param) ->
      where_fragment_apply_comparison_col_param(prp_stm, col, ">", param)
    WhereColGreaterOrEqualParam(col, param) ->
      where_fragment_apply_comparison_col_param(prp_stm, col, ">=", param)
    WhereColNotEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereColNotEqualParam(col, param) ->
      where_fragment_apply_comparison_col_param(prp_stm, col, "<>", param)
    WhereParamEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    WhereParamEqualCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, "=", col)
    WhereParamLowerCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, "<", col)
    WhereParamLowerOrEqualCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, "<=", col)
    WhereParamGreaterCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, ">", col)
    WhereParamGreaterOrEqualCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, ">=", col)
    WhereParamNotEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereParamNotEqualCol(param, col) ->
      where_fragment_apply_comparison_param_col(prp_stm, param, "<>", col)
    AndWhere(frgmts) ->
      where_fragment_apply_logical_sql_operator("AND", frgmts, prp_stm)
    NotWhere(frgmts) ->
      where_fragment_apply_logical_sql_operator("NOT", frgmts, prp_stm)
    OrWhere(frgmts) ->
      where_fragment_apply_logical_sql_operator("OR", frgmts, prp_stm)
    WhereColInParams(col, params) ->
      where_fragment_apply_column_in_params(col, params, prp_stm)
    NoWhereFragment -> prp_stm
  }
}

pub fn where_fragment_append_to_prepared_statement_as_clause(
  fragment frgmt: WhereFragment,
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  case frgmt {
    NoWhereFragment -> prp_stm
    _ -> {
      prp_stm
      |> prepared_statement.with_sql(" WHERE ")
      |> where_fragment_append_to_prepared_statement(frgmt)
    }
  }
}

fn apply_comparison_col_col(prp_stm, a_col, sql_operator, b_col) {
  prepared_statement.with_sql(
    prp_stm,
    a_col <> " " <> sql_operator <> " " <> b_col,
  )
}

fn where_fragment_apply_comparison_col_param(prp_stm, col, sql_operator, param) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    col <> " " <> sql_operator <> " " <> next_param,
    param,
  )
}

fn where_fragment_apply_comparison_param_col(prp_stm, param, sql_operator, col) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    next_param <> " " <> sql_operator <> " " <> col,
    param,
  )
}

fn where_fragment_apply_logical_sql_operator(
  operator oprtr: String,
  fragments frgmts: List(WhereFragment),
  prepared_statement prp_stm: PreparedStatement,
) {
  let new_prep_stm = prp_stm |> prepared_statement.with_sql("(")
  let new_prep_stm =
    list.fold(
      frgmts,
      new_prep_stm,
      fn(acc: PreparedStatement, frgmt: WhereFragment) -> PreparedStatement {
        case acc == new_prep_stm {
          True ->
            acc
            |> where_fragment_append_to_prepared_statement(frgmt)
          False ->
            acc
            |> prepared_statement.with_sql(" " <> oprtr <> " ")
            |> where_fragment_append_to_prepared_statement(frgmt)
        }
      },
    )

  new_prep_stm |> prepared_statement.with_sql(")")
}

fn where_fragment_apply_column_in_params(
  column col: String,
  parameters params: List(Param),
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  let new_prep_stm = prp_stm |> prepared_statement.with_sql(col <> " IN (")

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

  new_prep_stm |> prepared_statement.with_sql(")")
}
