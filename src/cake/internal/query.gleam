// import cake/stdlib/iox
import cake/stdlib/listx
import gleam/int

// —————————————————————————————————————————————————————————————————————————— //
// ———— Query ——————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type Query {
  // TODO: Maybe move these to a ReadQuery wrapper type?
  Select(query: SelectQuery)
  Combined(query: CombinedQuery)
  // TODO: Maybe move these to a WriteQuery wrapper type?
  // Insert(query: InsertQuery
  // Update(query: UpdateQuery)
  // Delete(query: DeleteQuery)
}

pub fn query_select_wrap(qry: SelectQuery) -> Query {
  Select(qry)
}

pub fn query_combined_wrap(qry: CombinedQuery) -> Query {
  Combined(qry)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— OrderByDirectionPart ———————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type OrderByPart {
  OrderByColumnPart(column: String, direction: OrderByDirectionPart)
}

pub type OrderByDirectionPart {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn order_by_part_to_sql(order_by_part ordbpt: OrderByPart) {
  case ordbpt.direction {
    Asc -> "ASC NULLS LAST"
    Desc -> "DESC NULLS LAST"
    AscNullsFirst -> "ASC NULLS FIRST"
    DescNullsFirst -> "DESC NULLS FIRST"
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— Limit & Offset Part ————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub opaque type LimitOffsetPart {
  LimitOffset(limit: Int, offset: Int)
  LimitNoOffset(limit: Int)
  NoLimitOffset
}

pub fn limit_offset_new(limit lmt: Int, offset offst: Int) -> LimitOffsetPart {
  case lmt >= 0, offst >= 0 {
    True, True -> LimitOffset(limit: lmt, offset: offst)
    True, False -> LimitNoOffset(limit: lmt)
    False, _ -> NoLimitOffset
  }
}

pub fn limit_new(limit lmt: Int) -> LimitOffsetPart {
  case lmt >= 0 {
    True -> LimitNoOffset(limit: lmt)
    False -> NoLimitOffset
  }
}

pub fn limit_offset_apply(
  prepared_statement prp_stm: PreparedStatement,
  limit_part lmt_prt: LimitOffsetPart,
) -> PreparedStatement {
  case lmt_prt {
    LimitOffset(limit: lmt, offset: offst) ->
      " LIMIT " <> int.to_string(lmt) <> " OFFSET " <> int.to_string(offst)
    LimitNoOffset(limit: lmt) -> " LIMIT " <> int.to_string(lmt)
    NoLimitOffset -> ""
  }
  |> prepared_statement.with_sql(prp_stm, _)
}

pub fn limit_offset_get(select_query slct_qry: SelectQuery) -> LimitOffsetPart {
  slct_qry.limit_offset
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— Combined Query —————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type CombinedKind {
  Union
  UnionAll
  Except
  // Notice: ExceptAll Does not work on SQLite
  ExceptAll
  Intersect
  // NOTICE: IntersectAll Does not work on SQLite
  IntersectAll
}

// List of SQL parts that will be used to build a combined query
// such as UNION queries.
pub type CombinedQuery {
  CombinedQuery(
    kind: CombinedKind,
    select_queries: List(SelectQuery),
    limit_offset: LimitOffsetPart,
    // TODO: before adding epilog to combined, fix it for selects with a custom type
    order_by: List(OrderByPart),
    // Epilog allows you to append raw SQL to the end of queries.
    // You should never put raw user data into epilog.
    epilog: EpilogPart,
  )
}

pub fn combined_union_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  Union |> combined_query_new(slct_qrys)
}

pub fn combined_union_all_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  UnionAll |> combined_query_new(slct_qrys)
}

pub fn combined_except_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  Except |> combined_query_new(slct_qrys)
}

pub fn combined_except_all_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  ExceptAll |> combined_query_new(slct_qrys)
}

pub fn combined_intersect_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  Intersect |> combined_query_new(slct_qrys)
}

pub fn combined_intersect_all_query_new(
  select_queries slct_qrys: List(SelectQuery),
) -> CombinedQuery {
  IntersectAll |> combined_query_new(slct_qrys)
}

fn combined_query_new(
  kind: CombinedKind,
  select_queries: List(SelectQuery),
) -> CombinedQuery {
  let select_queries =
    combined_query_remove_order_by_from_selects(select_queries)
  CombinedQuery(
    kind: kind,
    select_queries: select_queries,
    limit_offset: NoLimitOffset,
    order_by: [],
    epilog: NoEpilogPart,
  )
}

fn combined_query_remove_order_by_from_selects(
  select_queries slct_qrys: List(SelectQuery),
) -> List(SelectQuery) {
  slct_qrys
  |> list.map(fn(slct_qry) { SelectQuery(..slct_qry, order_by: []) })
}

pub fn combined_get_select_queries(
  combined_query cq: CombinedQuery,
) -> List(SelectQuery) {
  cq.select_queries
}

// ———— LIMIT & OFFSET ————————————————————————————————————————————————————————— //

pub fn combined_query_set_limit(
  query qry: CombinedQuery,
  limit lmt: Int,
) -> CombinedQuery {
  let limit_offset = limit_new(lmt)
  CombinedQuery(..qry, limit_offset: limit_offset)
}

pub fn combined_query_set_limit_and_offset(
  query qry: CombinedQuery,
  limit lmt: Int,
  offset offst: Int,
) -> CombinedQuery {
  let limit_offset = limit_offset_new(limit: lmt, offset: offst)
  CombinedQuery(..qry, limit_offset: limit_offset)
}

// ———— ORDER BY —————————————————————————————————————————————————————————————————— //

pub fn combined_query_order_asc(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, Asc), True)
}

pub fn combined_query_order_asc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, AscNullsFirst), True)
}

pub fn combined_query_order_asc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, Asc), False)
}

pub fn combined_query_order_asc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, AscNullsFirst), False)
}

pub fn combined_query_order_desc(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, Desc), True)
}

pub fn combined_query_order_desc_nulls_first(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, DescNullsFirst), True)
}

pub fn combined_query_order_desc_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, Desc), False)
}

pub fn combined_query_order_desc_nulls_first_replace(
  query qry: CombinedQuery,
  by ordb: String,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, DescNullsFirst), False)
}

pub fn combined_query_order(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, dir), True)
}

pub fn combined_query_order_replace(
  query qry: CombinedQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> CombinedQuery {
  do_combined_order_by(qry, OrderByColumnPart(ordb, dir), False)
}

fn do_combined_order_by(
  query qry: CombinedQuery,
  by ordb: OrderByPart,
  append append: Bool,
) -> CombinedQuery {
  case append {
    True ->
      CombinedQuery(..qry, order_by: qry.order_by |> listx.append_item(ordb))
    False -> CombinedQuery(..qry, order_by: listx.wrap(ordb))
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— Select Query ———————————————————————————————————————————————————————— //
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
    join: List(JoinPart),
    where: WherePart,
    // group_by: String,
    // having: String,
    // window: String,
    // values: String, ?
    // with_recursive: String, ?
    limit_offset: LimitOffsetPart,
    order_by: List(OrderByPart),
    epilog: EpilogPart,
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
    join: [],
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
  )
}

pub fn select_query_new_from(from from: FromPart) -> SelectQuery {
  SelectQuery(
    from: from,
    select: [],
    join: [],
    where: NoWherePart,
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
  )
}

pub fn select_query_new_select(select select: List(SelectPart)) -> SelectQuery {
  SelectQuery(
    from: NoFromPart,
    select: select,
    where: NoWherePart,
    join: [],
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
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
  where whr: WherePart,
) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

// ———— JOIN ——————————————————————————————————————————————————————————————— //

pub fn select_query_set_join(
  query qry: SelectQuery,
  join jn: List(JoinPart),
) -> SelectQuery {
  SelectQuery(..qry, join: jn)
}

// ———— ORDER BY ———————————————————————————————————————————————————————————— //

pub fn select_query_order_asc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, Asc), True)
}

pub fn select_query_order_asc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, AscNullsFirst), True)
}

pub fn select_query_order_asc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, Asc), False)
}

pub fn select_query_order_asc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, AscNullsFirst), False)
}

pub fn select_query_order_desc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, Desc), True)
}

pub fn select_query_order_desc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, DescNullsFirst), True)
}

pub fn select_query_order_desc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, Desc), False)
}

pub fn select_query_order_desc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, DescNullsFirst), False)
}

pub fn select_query_order(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, dir), True)
}

pub fn select_query_order_replace(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionPart,
) -> SelectQuery {
  do_select_order_by(qry, OrderByColumnPart(ordb, dir), False)
}

fn do_select_order_by(
  query qry: SelectQuery,
  by ordb: OrderByPart,
  append append: Bool,
) -> SelectQuery {
  case append {
    True ->
      SelectQuery(..qry, order_by: qry.order_by |> listx.append_item(ordb))
    False -> SelectQuery(..qry, order_by: listx.wrap(ordb))
  }
}

// ———— LIMIT & OFFSET ————————————————————————————————————————————————————————— //

pub fn select_query_set_limit(
  query qry: SelectQuery,
  limit lmt: Int,
) -> SelectQuery {
  let limit_offset = limit_new(lmt)
  SelectQuery(..qry, limit_offset: limit_offset)
}

pub fn select_query_set_limit_and_offset(
  query qry: SelectQuery,
  limit lmt: Int,
  offset offst: Int,
) -> SelectQuery {
  let limit_offset = limit_offset_new(limit: lmt, offset: offst)
  SelectQuery(..qry, limit_offset: limit_offset)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— From Part ——————————————————————————————————————————————————————————— //
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
// ———— Select Part ————————————————————————————————————————————————————————— //
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

pub fn select_part_from(s: String) -> SelectPart {
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
// ———— Where Part —————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

import cake/prepared_statement.{type PreparedStatement}

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
  WhereColLike(a_column: String, paramter: String)
  WhereColILike(a_column: String, parameter: String)
  // NOTICE: Sqlite does not support `SIMILAR TO`
  WhereColSimilarTo(a_column: String, parameter: String)
  // Parameter to column comparison
  WhereParamEqualCol(parameter: Param, column: String)
  WhereParamLowerCol(parameter: Param, column: String)
  WhereParamLowerOrEqualCol(parameter: Param, column: String)
  WhereParamGreaterCol(parameter: Param, column: String)
  WhereParamGreaterOrEqualCol(parameter: Param, column: String)
  WhereParamNotEqualCol(parameter: Param, column: String)
  // column IS [NOT] TRUE/FALSE
  WhereColIsBool(column: String, bool: Bool)
  WhereColIsNotBool(column: String, bool: Bool)
  // TODO: https://wiki.postgresql.org/wiki/Is_distinct_from
  // - WhereColIsDistinctFromCol(a_column: String, b_column: String)
  // - WhereColIsDistinctFromParam(column: String, parameter: Param)
  // Logical operators
  AndWhere(parts: List(WherePart))
  OrWhere(parts: List(WherePart))
  // TODO: XorWhere(List(WherePart))
  NotWhere(part: WherePart)
  // TODO: Subquery
  // - WhereColEqualSubquery(column: String, sub_query: Query)
  // - WhereColLowerSubquery(column: String, sub_query: Query)
  // - WhereColLowerOrEqualSubquery(column: String, sub_query: Query)
  // - WhereColGreaterSubquery(column: String, sub_query: Query)
  // - WhereColGreaterOrEqualSubquery(column: String, sub_query: Query)
  // - WhereColNotEqualSubquery(column: String, sub_query: Query)
  // Column contains value
  WhereColInParams(column: String, parameters: List(Param))
  // WhereColInSubquery(column: String, sub_query: Query)
  // Raw SQL
  // RawWhere(string: String, parameters: List(Param))
  NoWherePart
}

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

    WhereColLike(col, param) ->
      where_part_apply_comparison_col_param(
        prp_stm,
        col,
        "LIKE",
        param.StringParam(param),
      )
    WhereColILike(col, param) ->
      where_part_apply_comparison_col_param(
        prp_stm,
        col,
        "ILIKE",
        param.StringParam(param),
      )
    WhereColSimilarTo(col, param) ->
      where_part_apply_comparison_col_param(
        prp_stm,
        col,
        "SIMILAR TO",
        param.StringParam(param),
      )
      |> prepared_statement.with_sql(" ESCAPE '/'")

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
    WhereColIsBool(col, True) ->
      prepared_statement.with_sql(prp_stm, col <> " IS TRUE")
    WhereColIsBool(col, False) ->
      prepared_statement.with_sql(prp_stm, col <> " IS FALSE")
    WhereColIsNotBool(col, True) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT TRUE")
    WhereColIsNotBool(col, False) ->
      prepared_statement.with_sql(prp_stm, col <> " IS NOT FALSE")
    AndWhere(prts) ->
      where_part_apply_logical_sql_operator("AND", prts, prp_stm)
    OrWhere(prts) -> where_part_apply_logical_sql_operator("OR", prts, prp_stm)
    NotWhere(prt) -> {
      prp_stm
      |> prepared_statement.with_sql("NOT (")
      |> where_part_append_to_prepared_statement(prt)
      |> prepared_statement.with_sql(")")
    }
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

pub fn join_parts_append_to_prepared_statement_as_clause(
  parts prts: List(JoinPart),
  prepared_statement prp_stm: PreparedStatement,
) -> PreparedStatement {
  prts
  |> list.fold(
    prp_stm,
    fn(acc: PreparedStatement, prt: JoinPart) -> PreparedStatement {
      case acc == prp_stm {
        True -> {
          let join_command = case prt.kind {
            InnerJoin -> "INNER JOIN"
            LeftOuterJoin -> "LEFT JOIN"
            RightOuterJoin -> "RIGHT JOIN"
            FullOuterJoin -> "FULL JOIN"
            CrossJoin -> "CROSS JOIN"
          }
          prp_stm
          |> prepared_statement.with_sql(" " <> join_command <> " ")
          |> prepared_statement.with_sql(prt.table <> " AS " <> prt.alias)
          |> prepared_statement.with_sql(" ON ")
          |> where_part_append_to_prepared_statement(prt.on)
        }
        False -> acc |> where_part_append_to_prepared_statement(prt.on)
      }
    },
  )
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

// —————————————————————————————————————————————————————————————————————————— //
// ———— Join Part ——————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub type JoinKind {
  CrossJoin
  InnerJoin
  LeftOuterJoin
  RightOuterJoin
  FullOuterJoin
}

pub type JoinPart {
  JoinPart(kind: JoinKind, table: String, alias: String, on: WherePart)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— Epilog Part ————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub opaque type EpilogPart {
  Epilog(string: String)
  NoEpilogPart
}

pub fn epilog_new(epilog: String) -> EpilogPart {
  case epilog {
    "" -> NoEpilogPart
    _ -> Epilog(string: epilog)
  }
}

pub fn epilog_apply(
  prepared_statement prp_stm: PreparedStatement,
  epilog_part epl_prt: EpilogPart,
) -> PreparedStatement {
  case epl_prt {
    NoEpilogPart -> prp_stm
    Epilog(string: epl) -> epl |> prepared_statement.with_sql(prp_stm, _)
  }
}
