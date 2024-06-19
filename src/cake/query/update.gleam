//// A DSL to build `UPDATE` queries.
////

import cake/internal/query.{type Query, Comment, NoComment, NoWhere}
import cake/internal/write_query.{
  type Update, type UpdateSet, type UpdateSets, type WriteQuery, NoReturning,
  NoUpdateFrom, NoUpdateModifier, Returning, Update, UpdateExpressionSet,
  UpdateParamSet, UpdateQuery, UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{type Param}
import gleam/string

pub fn to_query(update updt: Update(a)) -> WriteQuery(a) {
  updt |> UpdateQuery
}

pub fn bool(value vl: Bool) -> Param {
  vl |> param.bool
}

pub fn float(value vl: Float) -> Param {
  vl |> param.float
}

pub fn int(value vl: Int) -> Param {
  vl |> param.int
}

pub fn string(value vl: String) -> Param {
  vl |> param.string
}

pub fn new(table tbl: String, sets sts: List(UpdateSet)) -> Update(a) {
  Update(
    // with (_recursive?): ?, // v2
    modifier: NoUpdateModifier,
    table: UpdateTable(tbl),
    set: UpdateSets(sts),
    from: NoUpdateFrom,
    where: NoWhere,
    returning: NoReturning,
    comment: NoComment,
  )
}

pub fn col_to_param(column col: String, param prm: Param) -> UpdateSet {
  UpdateParamSet(column: col, param: prm)
}

pub fn col_to_expression(
  column col: String,
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: [col], expression: exp)
}

pub fn col_to_sub_query(column col: String, sub_query qry: Query) -> UpdateSet {
  UpdateSubQuerySet(columns: [col], sub_query: qry)
}

pub fn cols_to_expression(
  columns cols: List(String),
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: cols, expression: exp)
}

pub fn cols_to_sub_query(
  columns cols: List(String),
  sub_query qry: Query,
) -> UpdateSet {
  UpdateSubQuerySet(columns: cols, sub_query: qry)
}

pub fn returning(
  query qry: Update(a),
  returning rtrn: List(String),
) -> Update(a) {
  case rtrn {
    [] -> Update(..qry, returning: NoReturning)
    _ -> Update(..qry, returning: Returning(rtrn))
  }
}

pub fn no_returning(query qry: Update(a)) -> Update(a) {
  Update(..qry, returning: NoReturning)
}

pub fn comment(query qry: Update(a), comment cmmnt: String) -> Update(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Update(..qry, comment: NoComment)
    _ -> Update(..qry, comment: Comment(cmmnt))
  }
}

pub fn no_comment(query qry: Update(a)) -> Update(a) {
  Update(..qry, comment: NoComment)
}
