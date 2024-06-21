//// A DSL to build `UPDATE` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type Query, Comment, Epilog, NoComment, NoEpilog,
  NoWhere,
}
import cake/internal/write_query.{
  type Update, type UpdateSet, type UpdateSets, type WriteQuery, NoReturning,
  NoUpdateFrom, NoUpdateModifier, Returning, Update, UpdateExpressionSet,
  UpdateParamSet, UpdateQuery, UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{type Param}
import gleam/string

/// Creates a `WriteQuery` from an `Update`.
///
pub fn to_query(update updt: Update(a)) -> WriteQuery(a) {
  updt |> UpdateQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

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

// ▒▒▒ Constructor ▒▒▒

pub fn new(table tbl: String, sets sts: List(UpdateSet)) -> Update(a) {
  Update(
    modifier: NoUpdateModifier,
    table: UpdateTable(tbl),
    set: UpdateSets(sts),
    from: NoUpdateFrom,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Set ▒▒▒

pub fn set_to_param(column col: String, param prm: Param) -> UpdateSet {
  UpdateParamSet(column: col, param: prm)
}

pub fn set_to_expression(
  column col: String,
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: [col], expression: exp)
}

pub fn set_to_sub_query(column col: String, sub_query qry: Query) -> UpdateSet {
  UpdateSubQuerySet(columns: [col], sub_query: qry)
}

pub fn set_many_to_expression(
  columns cols: List(String),
  expression exp: String,
) -> UpdateSet {
  UpdateExpressionSet(columns: cols, expression: exp)
}

pub fn set_many_to_sub_query(
  columns cols: List(String),
  sub_query qry: Query,
) -> UpdateSet {
  UpdateSubQuerySet(columns: cols, sub_query: qry)
}

// TODO v1 From
// TODO v1 Where

// ▒▒▒ RETURNING ▒▒▒

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
///         they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn returning(
  query qry: Update(a),
  returning rtrn: List(String),
) -> Update(a) {
  case rtrn {
    [] -> Update(..qry, returning: NoReturning)
    _ -> Update(..qry, returning: Returning(rtrn))
  }
}

/// NOTICE: MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries;
///         they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(query qry: Update(a)) -> Update(a) {
  Update(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

pub fn epilog(query qry: Update(a), epilog eplg: String) -> Update(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Update(..qry, epilog: NoEpilog)
    _ -> Update(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn no_epilog(query qry: Update(a)) -> Update(a) {
  Update(..qry, epilog: NoEpilog)
}

pub fn get_epilog(query qry: Update(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

pub fn comment(query qry: Update(a), comment cmmnt: String) -> Update(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Update(..qry, comment: NoComment)
    _ -> Update(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

pub fn no_comment(query qry: Update(a)) -> Update(a) {
  Update(..qry, comment: NoComment)
}

pub fn get_comment(query qry: Update(a)) -> Comment {
  qry.comment
}
