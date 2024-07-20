//// A DSL to build `DELETE` queries.
////

import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins, NoComment, NoEpilog,
  NoJoins, NoWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  Delete, DeleteModifier, DeleteQuery, DeleteTable, DeleteUsing,
  NoDeleteModifier, NoDeleteTable, NoDeleteUsing, NoReturning, Returning,
}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Comment =
  read_query.Comment

pub type Epilog =
  read_query.Epilog

pub type From =
  read_query.From

pub type Join =
  read_query.Join

pub type Joins =
  read_query.Joins

pub type ReadQuery =
  read_query.ReadQuery

pub type Where =
  read_query.Where

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  write_query type re-exports                                              │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Delete(a) =
  write_query.Delete(a)

pub type DeleteTable =
  write_query.DeleteTable

pub type DeleteUsing =
  write_query.DeleteUsing

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Creates a `WriteQuery` from a `Delete` query.
///
pub fn to_query(delete dlt: Delete(a)) -> WriteQuery(a) {
  dlt |> DeleteQuery
}

// ▒▒▒ Constructors ▒▒▒

/// Creates an empty `Delete` query.
///
pub fn new() -> Delete(a) {
  Delete(
    modifier: NoDeleteModifier,
    table: NoDeleteTable,
    using: NoDeleteUsing,
    join: NoJoins,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Modifier ▒▒▒

/// Sets the `DELETE` modifier.
///
pub fn modifier(delete dlt: Delete(a), modifier mdfr: String) -> Delete(a) {
  let mdfr = mdfr |> string.trim
  case mdfr {
    "" -> Delete(..dlt, modifier: NoDeleteModifier)
    _ -> Delete(..dlt, modifier: mdfr |> DeleteModifier)
  }
}

/// Removes the `DELETE` modifier.
///
pub fn no_modifier(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, modifier: NoDeleteModifier)
}

/// Gets the `DELETE` modifier.
///
pub fn get_modifier(delete dlt: Delete(a)) -> String {
  case dlt.modifier {
    NoDeleteModifier -> ""
    DeleteModifier(mdfr) -> mdfr
  }
}

// ▒▒▒ Table ▒▒▒

/// Sets the table name of the `Delete` query, aka the table where
/// the rows will be deleted from.
///
pub fn table(delete dlt: Delete(a), table_name tbl_nm: String) -> Delete(a) {
  Delete(..dlt, table: tbl_nm |> DeleteTable)
}

/// Removes the table name from the `Delete` query.
///
pub fn no_table(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, table: NoDeleteTable)
}

/// Gets the table name of the `Delete` query.
///
pub fn get_table(delete dlt: Delete(a)) -> DeleteTable {
  dlt.table
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
/// NOTICE: SQLite does not support `USING`.
///
/// NOTICE: For MariaDB and MySQL it is mandatory to specify the table specified
/// in the `FROM` clause in the `USING` clause, again - e.g. in raw SQL:
/// `DELETE * FROM a USING a, b, WHERE a.b_id = b.id;`
///
pub fn using_table(
  delete dlt: Delete(a),
  table_name tbl_nm: String,
) -> Delete(a) {
  case dlt.using {
    NoDeleteUsing -> Delete(..dlt, using: [tbl_nm |> FromTable] |> DeleteUsing)
    DeleteUsing(dlt_usngs) ->
      Delete(
        ..dlt,
        using: dlt_usngs |> list.append([tbl_nm |> FromTable]) |> DeleteUsing,
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
/// NOTICE: SQLite does not support `USING`.
///
/// NOTICE: MariaDB and MySQL may not support sub-queries in the `USING` clause.
/// In such case you may use a sub-query in a `WHERE` clause,  or use a join
/// instead.
///
pub fn using_sub_query(
  delete dlt: Delete(a),
  query qry: ReadQuery,
  alias als: String,
) -> Delete(a) {
  case dlt.using {
    NoDeleteUsing ->
      Delete(..dlt, using: [qry |> FromSubQuery(alias: als)] |> DeleteUsing)
    DeleteUsing(dlt_usngs) ->
      Delete(
        ..dlt,
        using: dlt_usngs
          |> list.append([qry |> FromSubQuery(alias: als)])
          |> DeleteUsing,
      )
  }
}

/// Replaces the `USING` clause of the `Delete` query with a table.
///
pub fn replace_using_table(
  delete dlt: Delete(a),
  table_name tbl_nm: String,
) -> Delete(a) {
  case dlt.using {
    NoDeleteUsing -> Delete(..dlt, using: [tbl_nm |> FromTable] |> DeleteUsing)
    DeleteUsing(_) -> Delete(..dlt, using: [tbl_nm |> FromTable] |> DeleteUsing)
  }
}

/// Replaces the `USING` clause of the `Delete` query with a sub-query.
///
pub fn replace_using_sub_query(
  delete dlt: Delete(a),
  query qry: ReadQuery,
  alias als: String,
) -> Delete(a) {
  case dlt.using {
    NoDeleteUsing ->
      Delete(..dlt, using: [qry |> FromSubQuery(alias: als)] |> DeleteUsing)
    DeleteUsing(_) ->
      Delete(..dlt, using: [qry |> FromSubQuery(alias: als)] |> DeleteUsing)
  }
}

/// Removes the `USING` clause from the `Delete` query.
///
pub fn no_using(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, using: NoDeleteUsing)
}

/// Gets the `USING` clause of the `Delete` query.
///
pub fn get_using(delete dlt: Delete(a)) -> List(From) {
  case dlt.using {
    NoDeleteUsing -> []
    DeleteUsing(usng) -> usng
  }
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Delete` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn join(delete dlt: Delete(a), join jn: Join) -> Delete(a) {
  case dlt.join {
    Joins(jns) -> Delete(..dlt, join: jns |> list.append([jn]) |> Joins)
    NoJoins -> Delete(..dlt, join: [jn] |> Joins)
  }
}

/// Replaces any `Join`s of the `Delete` query with a signle `Join`.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_join(delete dlt: Delete(a), join jn: Join) -> Delete(a) {
  Delete(..dlt, join: [jn] |> Joins)
}

/// Adds `Join`s to the `Delete` query.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn joins(delete dlt: Delete(a), joins jns: List(Join)) -> Delete(a) {
  case jns, dlt.join {
    [], _ -> Delete(..dlt, join: jns |> Joins)
    jns, Joins(dlt_joins) ->
      Delete(..dlt, join: dlt_joins |> list.append(jns) |> Joins)
    jns, NoJoins -> Delete(..dlt, join: jns |> Joins)
  }
}

/// Replaces any `Join`s of the `Delete` query with the given `Join`s.
///
/// NOTICE: On Postgres/SQLite `Joins` are only allowed if the `FROM` clause is
/// set as well.
///
pub fn replace_joins(delete dlt: Delete(a), joins jns: List(Join)) -> Delete(a) {
  Delete(..dlt, join: jns |> Joins)
}

/// Removes any `Joins` from the `Delete` query.
///
pub fn no_join(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, join: NoJoins)
}

/// Gets the `Joins` of the `Delete` query.
///
pub fn get_joins(delete dlt: Delete(a)) -> Joins {
  dlt.join
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
pub fn where(delete dlt: Delete(a), where whr: Where) -> Delete(a) {
  case dlt.where {
    NoWhere -> Delete(..dlt, where: whr)
    AndWhere(wheres) ->
      Delete(..dlt, where: wheres |> list.append([whr]) |> AndWhere)
    _ -> Delete(..dlt, where: [dlt.where, whr] |> AndWhere)
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
pub fn or_where(delete dlt: Delete(a), where whr: Where) -> Delete(a) {
  case dlt.where {
    NoWhere -> Delete(..dlt, where: whr)
    OrWhere(wheres) ->
      Delete(..dlt, where: wheres |> list.append([whr]) |> OrWhere)
    _ -> Delete(..dlt, where: [dlt.where, whr] |> OrWhere)
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
/// NOTICE: This operator does not exist in Postgres or SQLite, and *Cake*
/// generates equivalent SQL using `OR` and `AND` and `NOT`.
/// This operator exists in MariaDB/MySQL.
///
pub fn xor_where(delete dlt: Delete(a), where whr: Where) -> Delete(a) {
  case dlt.where {
    NoWhere -> Delete(..dlt, where: whr)
    XorWhere(wheres) ->
      Delete(..dlt, where: wheres |> list.append([whr]) |> XorWhere)
    _ -> Delete(..dlt, where: [dlt.where, whr] |> XorWhere)
  }
}

/// Replaces the `Where` in the `Delete` query.
///
pub fn replace_where(delete dlt: Delete(a), where whr: Where) -> Delete(a) {
  Delete(..dlt, where: whr)
}

/// Removes the `Where` from the `Delete` query.
///
pub fn no_where(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, where: NoWhere)
}

/// Gets the `Where` of the `Delete` query.
///
pub fn get_where(delete dlt: Delete(a)) -> Where {
  dlt.where
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `Delete` query.
///
pub fn returning(
  delete dlt: Delete(a),
  returning rtrn: List(String),
) -> Delete(a) {
  case rtrn {
    [] -> Delete(..dlt, returning: NoReturning)
    _ -> Delete(..dlt, returning: rtrn |> Returning)
  }
}

/// Specify that no columns should be returned after the `Delete` query.
///
pub fn no_returning(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `Delete` query.
///
pub fn epilog(delete dlt: Delete(a), epilog eplg: String) -> Delete(a) {
  let eplg = eplg |> string.trim
  case eplg {
    "" -> Delete(..dlt, epilog: NoEpilog)
    _ -> Delete(..dlt, epilog: { " " <> eplg } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `Delete` query.
///
pub fn no_epilog(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, epilog: NoEpilog)
}

/// Get the epilog from an `Delete` query.
///
pub fn get_epilog(delete dlt: Delete(a)) -> Epilog {
  dlt.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `Delete` query.
///
pub fn comment(delete dlt: Delete(a), comment cmmnt: String) -> Delete(a) {
  let cmmnt = cmmnt |> string.trim
  case cmmnt {
    "" -> Delete(..dlt, comment: NoComment)
    _ -> Delete(..dlt, comment: { " " <> cmmnt } |> Comment)
  }
}

/// Specify that no comment should be added to the `Delete` query.
///
pub fn no_comment(delete dlt: Delete(a)) -> Delete(a) {
  Delete(..dlt, comment: NoComment)
}

/// Get the comment from an `Delete` query.
///
pub fn get_comment(delete dlt: Delete(a)) -> Comment {
  dlt.comment
}
