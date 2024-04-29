// —————————————————————————————————————————————————————————————————————————— //
// ———— Query ——————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type Query {
  Select(
    query: SelectQuery,
    // Epilog allows you to append raw SQL to the end of queries.
    // You should never put raw user data into epilog.
    epilog: String,
  )
  Union(
    query: UnionQuery,
    // Epilog allows you to append raw SQL to the end of queries.
    // You should never put raw user data into epilog.
    epilog: String,
  )
}

pub fn query_select_wrap(qry: SelectQuery) -> Query {
  Select(qry, epilog: "")
}

pub fn query_union_wrap(qry: UnionQuery) -> Query {
  Union(qry, epilog: "")
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SelectQuery ————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

// List of SQL parts that will be used to build a select query.
pub type SelectQuery {
  SelectQuery(
    from: FromPart,
    // comment: String,
    // modifier: String,
    // with: String,
    select: List(SelectPart),
    // distinct: String,
    // join: String,
    where: WherePart,
    // group_by: String,
    // having: String,
    // window: String,
    // TODO: as not just SELECT but also UNION and maybe other causes
    // use order_by, limit and offset, possibly make them real types, too
    // at least alias them
    order_by: List(#(String, OrderByDirectionPart)),
    limit: Int,
    offset: Int,
  )
}

// ———— NEW ————————————————————————————————————————————————————————————————— //

pub fn select_query_new(
  from from: FromPart,
  select select: List(SelectPart),
) -> SelectQuery {
  SelectQuery(
    from: from,
    select: select,
    where: NoWherePart,
    order_by: [],
    limit: -1,
    offset: -1,
  )
}

pub fn select_query_new_from(from from: FromPart) -> SelectQuery {
  SelectQuery(
    from: from,
    select: [],
    where: NoWherePart,
    order_by: [],
    limit: -1,
    offset: -1,
  )
}

pub fn select_query_new_select(select select: List(SelectPart)) -> SelectQuery {
  SelectQuery(
    from: NoFromPart,
    select: select,
    where: NoWherePart,
    order_by: [],
    limit: -1,
    offset: -1,
  )
}

// ———— FROM ———————————————————————————————————————————————————————————————— //

pub fn select_query_set_from(
  query qry: SelectQuery,
  from from: FromPart,
) -> SelectQuery {
  SelectQuery(..qry, from: from)
}

// ———— SELECT —————————————————————————————————————————————————————————————— //

pub fn select_query_select(
  query qry: SelectQuery,
  select select: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, select))
}

pub fn select_query_select_replace(
  query qry: SelectQuery,
  select select: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: select)
}

// ———— WHERE ——————————————————————————————————————————————————————————————— //

pub fn select_query_set_where(
  query qry: SelectQuery,
  where where: WherePart,
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
  direction dir: OrderByDirectionPart,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), True)
}

pub fn select_query_order_replace(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), False)
}

import cake/stdlib/listx

fn do_order_by(
  query qry: SelectQuery,
  by ordb: #(String, OrderByDirectionPart),
  append append: Bool,
) -> SelectQuery {
  case append {
    True ->
      SelectQuery(..qry, order_by: qry.order_by |> listx.append_item(ordb))
    False -> SelectQuery(..qry, order_by: [ordb])
  }
}

// ———— LIMIT & OFFSET —————————————————————————————————————————————————————— //

pub fn select_query_set_limit(qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  case lmt >= 0 {
    True -> SelectQuery(..qry, limit: lmt)
    // TODO: Add debug warning, negative limit is ignored
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
pub type UnionQuery {
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
    // TODO: UNION vs UNION ALL vs EXCEPT vs INTERSECT
    UnionDistinctQuery(select_queries) -> select_queries
    UnionAllQuery(select_queries) -> select_queries
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— FromPart ———————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type FromPart {
  FromString(String)
  // TODO: check if the table does indeed exist
  FromTable(String)
  NoFromPart
}

pub fn from_part_from_table(s: String) -> FromPart {
  FromTable(s)
}

pub fn from_part_to_sql(part prt: FromPart) {
  case prt {
    FromString(s) -> " FROM " <> s
    FromTable(s) -> " FROM " <> s
    NoFromPart -> ""
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— OrderByDirectionPart ———————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type OrderByDirectionPart {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn order_by_direction_part_to_sql(part prt: OrderByDirectionPart) {
  case prt {
    Asc -> " ASC NULLS LAST"
    Desc -> " DESC NULLS LAST"
    AscNullsFirst -> " ASC NULLS FIRST"
    DescNullsFirst -> " DESC NULLS FIRST"
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SelectPart —————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type SelectPart {
  // Strings are arbitrary SQL strings
  // Aliases rename fields
  SelectString(string: String)
  SelectStringAlias(string: String, alias: String)
  // Columns are:
  // - auto prefixed? by their corresponding tables if not given
  // - checked if they exist
  SelectColumn(column: String)
  SelectColumnAlias(column: String, alias: String)
  // RawSelect(string: String, parameters: List(Param))
}

pub fn select_part_from_string(s: String) -> SelectPart {
  // TODO: check if the table does indeed exist
  SelectString(s)
}

pub fn select_part_to_sql(part prt: SelectPart) {
  case prt {
    SelectString(string) -> string
    SelectStringAlias(string, alias) -> string <> " AS " <> alias
    SelectColumn(column) -> column
    SelectColumnAlias(column, alias) -> column <> " AS " <> alias
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— WherePart ——————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

import cake/prepared_statement.{type PreparedStatement}

// import cake/stdlib/iox
import cake/param.{type Param, NullParam}

// import cake/query.{type Query}
import gleam/list

pub type WherePart {
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
  AndWhere(parts: List(WherePart))
  NotWhere(parts: List(WherePart))
  OrWhere(parts: List(WherePart))
  // XorWhere(List(WherePart))
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
  // Raw SQL
  // RawWhere(string: String, parameters: List(Param))
  NoWherePart
}

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
fn where_part_append_to_prepared_statement(
  prepared_statement prp_stm: PreparedStatement,
  part prt: WherePart,
) -> PreparedStatement {
  case prt {
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
      where_part_apply_comparison_col_param(prp_stm, col, "=", param)
    WhereColLowerParam(col, param) ->
      where_part_apply_comparison_col_param(prp_stm, col, "<", param)
    WhereColLowerOrEqualParam(col, param) ->
      where_part_apply_comparison_col_param(prp_stm, col, "<=", param)
    WhereColGreaterParam(col, param) ->
      where_part_apply_comparison_col_param(prp_stm, col, ">", param)
    WhereColGreaterOrEqualParam(col, param) ->
      where_part_apply_comparison_col_param(prp_stm, col, ">=", param)
    WhereColNotEqualParam(col, NullParam) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereColNotEqualParam(col, param) ->
      where_part_apply_comparison_col_param(prp_stm, col, "<>", param)
    WhereParamEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NULL")
    WhereParamEqualCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, "=", col)
    WhereParamLowerCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, "<", col)
    WhereParamLowerOrEqualCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, "<=", col)
    WhereParamGreaterCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, ">", col)
    WhereParamGreaterOrEqualCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, ">=", col)
    WhereParamNotEqualCol(NullParam, col) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT NULL")
    WhereParamNotEqualCol(param, col) ->
      where_part_apply_comparison_param_col(prp_stm, param, "<>", col)
    AndWhere(prts) ->
      where_part_apply_logical_sql_operator("AND", prts, prp_stm)
    NotWhere(prts) ->
      where_part_apply_logical_sql_operator("NOT", prts, prp_stm)
    OrWhere(prts) -> where_part_apply_logical_sql_operator("OR", prts, prp_stm)
    WhereColInParams(col, params) ->
      where_part_apply_column_in_params(col, params, prp_stm)
    NoWherePart -> prp_stm
  }
}

pub fn where_part_append_to_prepared_statement_as_clause(
  part prt: WherePart,
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  case prt {
    NoWherePart -> prp_stm
    _ -> {
      prp_stm
      |> prepared_statement.with_sql(" WHERE ")
      |> where_part_append_to_prepared_statement(prt)
    }
  }
}

fn apply_comparison_col_col(prp_stm, a_col, sql_operator, b_col) {
  prp_stm
  |> prepared_statement.with_sql(a_col <> " " <> sql_operator <> " " <> b_col)
}

fn where_part_apply_comparison_col_param(prp_stm, col, sql_operator, param) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    col <> " " <> sql_operator <> " " <> next_param,
    param,
  )
}

fn where_part_apply_comparison_param_col(prp_stm, param, sql_operator, col) {
  let next_param = prepared_statement.next_param(prp_stm)

  prepared_statement.with_sql_and_param(
    prp_stm,
    next_param <> " " <> sql_operator <> " " <> col,
    param,
  )
}

fn where_part_apply_logical_sql_operator(
  operator oprtr: String,
  parts prts: List(WherePart),
  prepared_statement prp_stm: PreparedStatement,
) {
  let new_prep_stm = prp_stm |> prepared_statement.with_sql("(")
  list.fold(
    prts,
    new_prep_stm,
    fn(acc: PreparedStatement, prt: WherePart) -> PreparedStatement {
      case acc == new_prep_stm {
        True -> acc |> where_part_append_to_prepared_statement(prt)
        False ->
          acc
          |> prepared_statement.with_sql(" " <> oprtr <> " ")
          |> where_part_append_to_prepared_statement(prt)
      }
    },
  )
  |> prepared_statement.with_sql(")")
}

fn where_part_apply_column_in_params(
  column col: String,
  parameters params: List(Param),
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  let new_prep_stm = prp_stm |> prepared_statement.with_sql(col <> " IN (")
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
  |> prepared_statement.with_sql(")")
}
