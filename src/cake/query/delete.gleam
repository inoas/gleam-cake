//// A DSL to build `DELETE` queries.
////

import cake/internal/query.{
  type Comment, type Epilog, type From, type Query, type Where, AndWhere,
  Comment, Epilog, FromSubQuery, FromTable, NoComment, NoEpilog, NoWhere,
  OrWhere, XorWhere,
}
import cake/internal/write_query.{
  type Delete, type DeleteUsing, type WriteQuery, Delete, DeleteModifier,
  DeleteQuery, DeleteTable, DeleteUsing, NoDeleteModifier, NoDeleteUsing,
  NoReturning, Returning,
}
import gleam/list
import gleam/string

/// Creates a `WriteQuery` from a `Delete` query.
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
    using: NoDeleteUsing,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Modifier ▒▒▒

/// Sets the `DELETE` modifier.
///
pub fn modifier(query qry: Delete(a), modifier mdfr: String) -> Delete(a) {
  let mdfr = mdfr |> string.trim
  case mdfr {
    "" -> Delete(..qry, modifier: NoDeleteModifier)
    _ -> Delete(..qry, modifier: DeleteModifier(mdfr))
  }
}

/// Removes the `DELETE` modifier.
///
pub fn no_modifier(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, modifier: NoDeleteModifier)
}

/// Gets the `DELETE` modifier.
///
pub fn get_modifier(query qry: Delete(a)) -> String {
  case qry.modifier {
    NoDeleteModifier -> ""
    DeleteModifier(mdfr) -> mdfr
  }
}

// ▒▒▒ Table ▒▒▒

/// Sets the table name of the `Delete` query, aka the table where
/// the rows will be deleted from.
///
pub fn table(query qry: Delete(a), table_name tbl_nm: String) -> Delete(a) {
  Delete(..qry, table: DeleteTable(name: tbl_nm))
}

/// Gets the table name of the `Delete` query.
///
pub fn get_table(query qry: Delete(a)) -> String {
  qry.table.name
}

// ▒▒▒ USING ▒▒▒

/// Adds a `USING` clause to the `Delete` query specifing a table.
///
/// If the query already has a `USING` clause, the new `USING` clause
/// will be appended to the existing one.
///
/// The `USING` clause is used to specify additional tables that are used
/// to filter the rows to be deleted.
///
pub fn using_table(query qry: Delete(a), table tbl: String) -> Delete(a) {
  case qry.using {
    NoDeleteUsing -> Delete(..qry, using: [FromTable(name: tbl)] |> DeleteUsing)
    DeleteUsing(qry_usngs) ->
      Delete(
        ..qry,
        using: qry_usngs |> list.append([FromTable(name: tbl)]) |> DeleteUsing,
      )
  }
}

/// Adds a `USING` clause to the `Delete` query specifing a sub-query.
///
/// The sub-query must be aliased.
///
/// If the query already has a `USING` clause, the new `USING` clause
/// will be appended to the existing one.
///
/// The `USING` clause is used to specify additional tables that are used
/// to filter the rows to be deleted.
///
pub fn using_sub_query(
  query qry: Delete(a),
  sub_query sb_qry: Query,
  alias als: String,
) -> Delete(a) {
  case qry.using {
    NoDeleteUsing ->
      Delete(
        ..qry,
        using: [FromSubQuery(sub_query: sb_qry, alias: als)] |> DeleteUsing,
      )
    DeleteUsing(qry_usngs) ->
      Delete(
        ..qry,
        using: qry_usngs
          |> list.append([FromSubQuery(sub_query: sb_qry, alias: als)])
          |> DeleteUsing,
      )
  }
}

/// Replaces the `USING` clause of the `Delete` query with a table.
///
pub fn replace_using_table(query qry: Delete(a), table tbl: String) -> Delete(a) {
  case qry.using {
    NoDeleteUsing -> Delete(..qry, using: [FromTable(name: tbl)] |> DeleteUsing)
    DeleteUsing(_) ->
      Delete(..qry, using: [FromTable(name: tbl)] |> DeleteUsing)
  }
}

/// Replaces the `USING` clause of the `Delete` query with a sub-query.
///
pub fn replace_using_sub_query(
  query qry: Delete(a),
  sub_query sb_qry: Query,
  alias als: String,
) -> Delete(a) {
  case qry.using {
    NoDeleteUsing ->
      Delete(
        ..qry,
        using: [FromSubQuery(sub_query: sb_qry, alias: als)] |> DeleteUsing,
      )
    DeleteUsing(_) ->
      Delete(
        ..qry,
        using: [FromSubQuery(sub_query: sb_qry, alias: als)] |> DeleteUsing,
      )
  }
}

/// Removes the `USING` clause from the `Delete` query.
///
pub fn no_using(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, using: NoDeleteUsing)
}

/// Gets the `USING` clause of the `Delete` query.
///
pub fn get_using(query qry: Delete(a)) -> List(From) {
  case qry.using {
    NoDeleteUsing -> []
    DeleteUsing(usng) -> usng
  }
}

// ▒▒▒ WHERE ▒▒▒

/// Sets an `AndWhere` or appends into an existing `AndWhere`.
///
/// - If the outermost `Where` is an `AndWhere`, the new `Where` is appended
///   to the list within `AndWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
pub fn where(query qry: Delete(a), where whr: Where) -> Delete(a) {
  case qry.where {
    NoWhere -> Delete(..qry, where: whr)
    AndWhere(wheres) ->
      Delete(..qry, where: AndWhere(wheres |> list.append([whr])))
    _ -> Delete(..qry, where: AndWhere([qry.where, whr]))
  }
}

/// Sets an `OrWhere` or appends into an existing `OrWhere`.
///
/// - If the outermost `Where` is an `OrWhere`, the new `Where` is appended
///   to the list within `OrWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `OrWhere`.
///
pub fn or_where(query qry: Delete(a), where whr: Where) -> Delete(a) {
  case qry.where {
    NoWhere -> Delete(..qry, where: whr)
    OrWhere(wheres) ->
      Delete(..qry, where: OrWhere(wheres |> list.append([whr])))
    _ -> Delete(..qry, where: OrWhere([qry.where, whr]))
  }
}

/// Sets an `XorWhere` or appends into an existing `XorWhere`.
///
/// - If the outermost `Where` is an `XorWhere`, the new `Where` is appended
///   to the list within `XorWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `XorWhere`.
///
/// NOTICE: This operator does not exist in Postgres or Sqlite,
///         and *Cake* generates equivalent SQL using `OR` and `AND` and `NOT`.
///         This operator exists in MariaDB/MySQL.
///
pub fn xor_where(query qry: Delete(a), where whr: Where) -> Delete(a) {
  case qry.where {
    NoWhere -> Delete(..qry, where: whr)
    XorWhere(wheres) ->
      Delete(..qry, where: XorWhere(wheres |> list.append([whr])))
    _ -> Delete(..qry, where: XorWhere([qry.where, whr]))
  }
}

/// Replaces the `Where` in the `Delete` query.
///
pub fn replace_where(query qry: Delete(a), where whr: Where) -> Delete(a) {
  Delete(..qry, where: whr)
}

/// Removes the `Where` from the `Delete` query.
///
pub fn no_where(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, where: NoWhere)
}

/// Gets the `Where` of the `Delete` query.
///
pub fn get_where(query qry: Delete(a)) -> Where {
  qry.where
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `Delete` query.
///
pub fn returning(
  query qry: Delete(a),
  returning rtrn: List(String),
) -> Delete(a) {
  case rtrn {
    [] -> Delete(..qry, returning: NoReturning)
    _ -> Delete(..qry, returning: Returning(rtrn))
  }
}

/// Specify that no columns should be returned after the `Delete` query.
///
pub fn no_returning(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `Delete` query.
///
pub fn epilog(query qry: Delete(a), epilog eplg: String) -> Delete(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Delete(..qry, epilog: NoEpilog)
    _ -> Delete(..qry, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `Delete` query.
///
pub fn no_epilog(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, epilog: NoEpilog)
}

/// Get the epilog from an `Delete` query.
///
pub fn get_epilog(query qry: Delete(a)) -> Epilog {
  qry.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `Delete` query.
///
pub fn comment(query qry: Delete(a), comment cmmnt: String) -> Delete(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Delete(..qry, comment: NoComment)
    _ -> Delete(..qry, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Specify that no comment should be added to the `Delete` query.
///
pub fn no_comment(query qry: Delete(a)) -> Delete(a) {
  Delete(..qry, comment: NoComment)
}

/// Get the comment from an `Delete` query.
///
pub fn get_comment(query qry: Delete(a)) -> Comment {
  qry.comment
}
