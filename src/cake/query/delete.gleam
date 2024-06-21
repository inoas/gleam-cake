//// A DSL to build `DELETE` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, Comment, Epilog, NoComment, NoEpilog, NoWhere,
}
import cake/internal/write_query.{
  type Delete, type WriteQuery, Delete, DeleteModifier, DeleteQuery, DeleteTable,
  NoDeleteModifier, NoReturning, NoUsing, Returning,
}
import gleam/string

/// Creates a `WriteQuery` from a `Delete`.
///
pub fn to_query(delete dlt: Delete(a)) -> WriteQuery(a) {
  dlt |> DeleteQuery
}

// ▒▒▒ Constructors ▒▒▒

/// Creates an empty `Delete` query.
///
pub fn new(table_name tbl_nm: String) -> Delete(a) {
  Delete(
    modifier: NoDeleteModifier,
    table: DeleteTable(tbl_nm),
    using: NoUsing,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Modifier ▒▒▒

pub fn modifier(query qry: Delete(a), modifier mdfr: String) -> Delete(a) {
  let mdfr = mdfr |> string.trim
  case mdfr {
    "" -> Delete(..qry, modifier: NoDeleteModifier)
    _ -> Delete(..qry, modifier: DeleteModifier(mdfr))
  }
}

pub fn no_modifier(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, modifier: NoDeleteModifier)
}

pub fn get_modifier(query qry: Delete(a)) -> String {
  case qry.modifier {
    NoDeleteModifier -> ""
    DeleteModifier(mdfr) -> mdfr
  }
}

// ▒▒▒ Table ▒▒▒

pub fn table(query qry: Delete(a), table_name tbl_nm: String) -> Delete(a) {
  Delete(..qry, table: DeleteTable(name: tbl_nm))
}

pub fn get_table(query qry: Delete(a)) -> String {
  qry.table.name
}

// TODO v1 Using
// TODO v1 Where

// ▒▒▒ RETURNING ▒▒▒

pub fn returning(
  query qry: Delete(a),
  returning rtrn: List(String),
) -> Delete(a) {
  case rtrn {
    [] -> Delete(..qry, returning: NoReturning)
    _ -> Delete(..qry, returning: Returning(rtrn))
  }
}

pub fn no_returning(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

pub fn epilog(query qry: Delete(a), epilog eplg: String) -> Delete(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Delete(..qry, epilog: NoEpilog)
    _ -> Delete(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

pub fn no_epilog(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, epilog: NoEpilog)
}

pub fn get_epilog(query qry: Delete(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

pub fn comment(query qry: Delete(a), comment cmmnt: String) -> Delete(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Delete(..qry, comment: NoComment)
    _ -> Delete(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

pub fn no_comment(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, comment: NoComment)
}

pub fn get_comment(query qry: Delete(a)) -> Comment {
  qry.comment
}
