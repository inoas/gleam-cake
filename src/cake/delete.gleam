//// A DSL to build `DELETE` queries.
////
//// ## Aliases
////
//// ```gleam
//// import cake/delete as d
//// import cake/where as w
//// import cake/join as j
//// ```
////
//// ---
////
//// ## Query Lifecycle
////
//// ```mermaid
//// flowchart LR
////     A[d.new] --> B[d.table]
////     B --> C[d.using_table / d.join]
////     C --> D[d.where]
////     D --> E[d.returning]
////     E --> F[d.to_query]
//// ```
////
//// ---
////
//// ## Constructor
////
//// ### `new() -> Delete(a)`
////
//// Creates an empty `Delete` query.
////
//// ### `to_query(delete: Delete(a)) -> WriteQuery(a)`
////
//// Converts a `Delete` into a `WriteQuery` for execution.
////
//// ---
////
//// ## Table
////
//// ### `table(delete, table_name) -> Delete(a)`
////
//// Sets the table from which rows will be deleted.
////
//// ```gleam
//// d.new()
//// |> d.table("sessions")
//// |> d.where(w.lt(w.col("expires_at"), w.date(today)))
//// |> d.to_query
//// // DELETE FROM sessions WHERE expires_at < $1
//// ```
////
//// | Function             | Effect                     |
//// | ------               | ------                     |
//// | `table(delete, name)` | Set the target table      |
//// | `no_table(delete)`    | Remove the target table   |
////
//// ---
////
//// ## USING clause
////
//// `USING` allows referencing additional tables to filter which rows are deleted.
//// It is the `DELETE` equivalent of a `FROM` join-helper on 🐘 PostgreSQL.
////
//// ```mermaid
//// flowchart TD
////     A[DELETE FROM a] --> B{USING}
////     B -->|table| C[USING b]
////     B -->|sub-query| D[USING sub AS alias]
////     C --> E[WHERE a.b_id = b.id]
////     D --> E
//// ```
////
//// ### `using_table(delete, table_name) -> Delete(a)`
////
//// Appends a table reference to the `USING` clause.
////
//// ```gleam
//// d.new()
//// |> d.table("order_items")
//// |> d.using_table("orders")
//// |> d.where(w.and([
////   w.eq(w.col("order_items.order_id"), w.col("orders.id")),
////   w.eq(w.col("orders.status"), w.string("cancelled")),
//// ]))
//// // DELETE FROM order_items USING orders
//// // WHERE order_items.order_id = orders.id AND orders.status = $1
//// ```
////
//// ### `using_sub_query(delete, query, alias) -> Delete(a)`
////
//// Appends an aliased sub-query to the `USING` clause.
////
//// > 🦭 MariaDB and 🐬 MySQL do not support sub-queries in `USING` — use a `JOIN`
//// > or a `WHERE` sub-query instead.
////
//// ### Database compatibility for USING
////
//// | Database      | Table | Sub-query |
//// | ------------- | ----- | --------- |
//// | 🐘 PostgreSQL | ✅    | ✅        |
//// | 🦭 MariaDB    | ✅    | ❌        |
//// | 🐬 MySQL      | ✅    | ❌        |
//// | 🪶 SQLite     | ❌    | ❌        |
////
//// > For 🦭 MariaDB and 🐬 MySQL the primary table used in `FROM` must also be
//// > listed in `USING`. For example:
//// >
//// > ```sql
//// > DELETE a FROM a USING a, b WHERE a.b_id = b.id
//// > ```
////
//// ### Replace / remove variants
////
//// | Function                                              | Effect                         |
//// | ------                                                | ------ |
//// | `replace_using_table(delete, name)`         | Replace USING with one table     |
//// | `replace_using_sub_query(delete, query, alias)` | Replace USING with one sub-query |
//// | `no_using(delete)`                          | Remove USING clause              |
////
//// ---
////
//// ## JOIN
////
//// For 🦭 MariaDB and 🐬 MySQL, `JOIN` is the standard way to filter a `DELETE`
//// against another table.
////
//// > On 🐘 PostgreSQL and 🪶 SQLite, `JOIN` on a `DELETE` requires a `USING`
//// > clause to be set.
////
//// ```gleam
//// d.new()
//// |> d.table("order_items")
//// |> d.join(j.inner(
////   with: j.table("orders"),
////   on: w.eq(w.col("order_items.order_id"), w.col("orders.id")),
////   alias: "orders",
//// ))
//// |> d.where(w.eq(w.col("orders.status"), w.string("cancelled")))
//// ```
////
//// | Function                   | Effect                     |
//// | ------                     | ------                     |
//// | `join(delete, join)`            | Append one join            |
//// | `replace_join(delete, join)`    | Replace all joins with one |
//// | `joins(delete, joins)`          | Append many joins          |
//// | `replace_joins(delete, joins)`  | Replace all joins          |
//// | `no_join(delete)`               | Remove all joins           |
////
//// ---
////
//// ## WHERE clause
////
//// See [`cake/where`](where.md) for building `Where` values.
////
//// ### `where(delete, where) -> Delete(a)`
////
//// Adds a condition with `AND` semantics.
////
//// ```gleam
//// d.new()
//// |> d.table("users")
//// |> d.where(w.eq(w.col("active"), w.bool(False)))
//// |> d.where(w.lt(w.col("created_at"), w.date(cutoff)))
//// // DELETE FROM users WHERE active = $1 AND created_at < $2
//// ```
////
//// ### `or_where(delete, where) -> Delete(a)`
////
//// Combines with `OR` semantics.
////
//// ### `xor_where(delete, where) -> Delete(a)`
////
//// Combines with exactly-one-true `XOR` semantics. Implemented via a custom
//// `OR / AND / NOT` expansion on all adapters — native `XOR` is not used on any
//// adapter, including 🦭 MariaDB / 🐬 MySQL.
////
//// > For odd-parity XOR (matching 🦭 MariaDB / 🐬 MySQL native `XOR`), use
//// > `w.xor_parity` instead.
////
//// ### `not_where(delete, where) -> Delete(a)`
////
//// Negates the given condition with `NOT` and combines with `AND` semantics.
////
//// - If there is no current WHERE, the condition is set as a standalone `NOT`.
//// - If the outermost WHERE is an `AndWhere`, the negated condition is appended to it.
//// - Otherwise, the existing WHERE and the new `NOT` condition are wrapped in an `AndWhere`.
////
//// | Function                 | Effect                   |
//// | ------                   | ------                   |
//// | `replace_where(delete, where)` | Replace the entire WHERE |
//// | `no_where(delete)`             | Remove WHERE clause      |
////
//// ---
////
//// ## RETURNING
////
//// Fetch column values from the deleted rows.
////
//// > Only supported by 🐘 PostgreSQL and 🪶 SQLite.
////
//// ```gleam
//// d.new()
//// |> d.table("sessions")
//// |> d.where(w.eq(w.col("user_id"), w.int(42)))
//// |> d.returning(["id", "token"])
//// // DELETE FROM sessions WHERE user_id = $1 RETURNING id, token
//// ```
////
//// | Function             | Effect                   |
//// | ------               | ------                   |
//// | `returning(delete, cols)` | Return the listed columns |
//// | `no_returning(delete)`    | Remove RETURNING clause   |
////
//// ---
////
//// ## Modifier
////
//// A raw string modifier inserted after `DELETE`
//// (e.g. `LOW_PRIORITY` or `QUICK` for MySQL).
////
//// ```gleam
//// d.new() |> d.modifier("LOW_PRIORITY")
//// // DELETE LOW_PRIORITY FROM ...
//// ```
////
//// ---
////
//// ## Epilog and Comment
////
//// ```gleam
//// d.new()
//// |> d.table("audit_log")
//// |> d.where(w.lt(w.col("created_at"), w.date(cutoff)))
//// |> d.epilog("RETURNING id")
//// |> d.comment("purge old audit records")
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/delete as d
//// import cake/where as w
////
//// d.new()
//// |> d.table("messages")
//// |> d.where(w.and([
////   w.eq(w.col("read"), w.bool(True)),
////   w.lt(w.col("created_at"), w.date(thirty_days_ago)),
//// ]))
//// |> d.returning(["id"])
//// |> d.to_query
//// ```
////
////
//// <!-- html assets for docs gen -->
//// <style>
////  .page {
////    display: block;
////  }
////  .content {
////    width: auto;
////    max-width: none;
////  }
//// </style>
//// <!--<script src="https://cdn.jsdelivr.net/npm/@mermaid-js/tiny@11/dist/mermaid.tiny.js"></script>-->
//// <script
////   src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"
////   integrity="sha256-cBN+d7snO7LvlyuG6LBADMqL5TyyW/xFkRoYbcmGZd4="
////   crossorigin="anonymous"
//// ></script>
//// <script>
//// (callback => document.readyState !== 'loading' ? callback() : document.addEventListener('DOMContentLoaded', callback, { once: true }))(() => {
////   mermaid.initialize({ startOnLoad: false })
////   mermaid.run({
////     querySelector: ".language-mermaid",
////   })
//// })
//// </script>
////

import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins, NoComment, NoEpilog,
  NoJoins, NoWhere, NotWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  Delete, DeleteModifier, DeleteQuery, DeleteTable, DeleteUsing,
  NoDeleteModifier, NoDeleteTable, NoDeleteUsing, NoReturning, Returning,
}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
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
// │ write_query type re-exports                                               │
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
pub fn to_query(delete delete: Delete(a)) -> WriteQuery(a) {
  delete |> DeleteQuery
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
pub fn modifier(
  delete delete: Delete(a),
  modifier modifier: String,
) -> Delete(a) {
  let modifier = modifier |> string.trim
  case modifier {
    "" -> Delete(..delete, modifier: NoDeleteModifier)
    _ -> Delete(..delete, modifier: modifier |> DeleteModifier)
  }
}

/// Removes the `DELETE` modifier.
///
pub fn no_modifier(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, modifier: NoDeleteModifier)
}

/// Gets the `DELETE` modifier.
///
pub fn get_modifier(delete delete: Delete(a)) -> String {
  case delete.modifier {
    NoDeleteModifier -> ""
    DeleteModifier(keyword:) -> keyword
  }
}

// ▒▒▒ Table ▒▒▒

/// Sets the table name of the `Delete` query, aka the table where
/// the rows will be deleted from.
///
pub fn table(
  delete delete: Delete(a),
  table_name table_name: String,
) -> Delete(a) {
  Delete(..delete, table: table_name |> DeleteTable)
}

/// Removes the table name from the `Delete` query.
///
pub fn no_table(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, table: NoDeleteTable)
}

/// Gets the table name of the `Delete` query.
///
pub fn get_table(delete delete: Delete(a)) -> DeleteTable {
  delete.table
}

// ▒▒▒ USING ▒▒▒

/// Adds a `USING` clause to the `Delete` query specifying a table.
///
/// If the query already has a `USING` clause, the new `USING` clause
/// will be appended to the existing one.
///
/// The `USING` clause is used to specify additional tables that are used
/// to filter the rows to be deleted.
///
/// NOTICE: 🪶SQLite does not support `USING`.
///
/// NOTICE: For 🦭MariaDB and 🐬MySQL it is mandatory to specify the table set
/// within the `FROM` clause in the `USING` clause, again - e.g. in raw SQL:
/// `DELETE * FROM a USING a, b, WHERE a.b_id = b.id;`
///
pub fn using_table(
  delete delete: Delete(a),
  table_name table_name: String,
) -> Delete(a) {
  case delete.using {
    NoDeleteUsing ->
      Delete(..delete, using: [table_name |> FromTable] |> DeleteUsing)
    DeleteUsing(froms: delete_usings) ->
      Delete(
        ..delete,
        using: delete_usings
          |> list.append([table_name |> FromTable])
          |> DeleteUsing,
      )
  }
}

/// Adds a `USING` clause to the `Delete` query specifying a sub-query.
///
/// The sub-query must be aliased.
///
/// If the query already has a `USING` clause, the new `USING` clause
/// will be appended to the existing one.
///
/// The `USING` clause is used to specify additional tables that are used
/// to filter the rows to be deleted.
///
/// NOTICE: 🪶SQLite does not support `USING`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support derived tables (sub-queries)
/// in the `USING` clause of a multi-table `DELETE` - only literal table names
/// are accepted there. Use a sub-query in a `WHERE` clause or a `JOIN` instead.
///
/// NOTICE: 🪶SQLite does not support `USING` at all.
///
pub fn using_sub_query(
  delete delete: Delete(a),
  query query: ReadQuery,
  alias alias: String,
) -> Delete(a) {
  case delete.using {
    NoDeleteUsing ->
      Delete(..delete, using: [FromSubQuery(query, alias:)] |> DeleteUsing)
    DeleteUsing(froms: delete_usings) ->
      Delete(
        ..delete,
        using: delete_usings
          |> list.append([FromSubQuery(query, alias:)])
          |> DeleteUsing,
      )
  }
}

/// Replaces the `USING` clause of the `Delete` query with a table.
///
pub fn replace_using_table(
  delete delete: Delete(a),
  table_name table_name: String,
) -> Delete(a) {
  Delete(..delete, using: [table_name |> FromTable] |> DeleteUsing)
}

/// Replaces the `USING` clause of the `Delete` query with a sub-query.
///
pub fn replace_using_sub_query(
  delete delete: Delete(a),
  query query: ReadQuery,
  alias alias: String,
) -> Delete(a) {
  Delete(..delete, using: [FromSubQuery(query, alias:)] |> DeleteUsing)
}

/// Removes the `USING` clause from the `Delete` query.
///
pub fn no_using(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, using: NoDeleteUsing)
}

/// Gets the `USING` clause of the `Delete` query.
///
pub fn get_using(delete delete: Delete(a)) -> List(From) {
  case delete.using {
    NoDeleteUsing -> []
    DeleteUsing(froms: using) -> using
  }
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Delete` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn join(delete delete: Delete(a), join join: Join) -> Delete(a) {
  case delete.join {
    Joins(items: existing_joins) ->
      Delete(..delete, join: existing_joins |> list.append([join]) |> Joins)
    NoJoins -> Delete(..delete, join: [join] |> Joins)
  }
}

/// Replaces any `Join`s of the `Delete` query with a single `Join`.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_join(delete delete: Delete(a), join join: Join) -> Delete(a) {
  Delete(..delete, join: [join] |> Joins)
}

/// Adds `Join`s to the `Delete` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn joins(delete delete: Delete(a), joins joins: List(Join)) -> Delete(a) {
  case joins, delete.join {
    [], _ -> delete
    _, Joins(items: existing_joins) ->
      Delete(..delete, join: existing_joins |> list.append(joins) |> Joins)
    _, NoJoins -> Delete(..delete, join: joins |> Joins)
  }
}

/// Replaces any `Join`s of the `Delete` query with the given `Join`s.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_joins(
  delete delete: Delete(a),
  joins joins: List(Join),
) -> Delete(a) {
  Delete(..delete, join: joins |> Joins)
}

/// Removes any `Joins` from the `Delete` query.
///
pub fn no_join(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, join: NoJoins)
}

/// Gets the `Joins` of the `Delete` query.
///
pub fn get_joins(delete delete: Delete(a)) -> Joins {
  delete.join
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
pub fn where(delete delete: Delete(a), where where: Where) -> Delete(a) {
  case delete.where {
    NoWhere -> Delete(..delete, where:)
    AndWhere(conditions:) ->
      Delete(..delete, where: conditions |> list.append([where]) |> AndWhere)
    _ -> Delete(..delete, where: [delete.where, where] |> AndWhere)
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
pub fn or_where(delete delete: Delete(a), where where: Where) -> Delete(a) {
  case delete.where {
    NoWhere -> Delete(..delete, where:)
    OrWhere(conditions:) ->
      Delete(..delete, where: conditions |> list.append([where]) |> OrWhere)
    _ -> Delete(..delete, where: [delete.where, where] |> OrWhere)
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
/// NOTICE: *Cake* implements this using a custom `OR / AND / NOT` expansion
/// on all four adapters (🐘PostgreSQL, 🪶SQLite, 🦭MariaDB, 🐬MySQL) —
/// native `XOR` is **not** used on any adapter.
///
/// For odd-parity XOR (which on 🦭MariaDB / 🐬MySQL delegates to its native
/// `XOR`) use `where.xor_parity` instead.
///
pub fn xor_where(delete delete: Delete(a), where where: Where) -> Delete(a) {
  case delete.where {
    NoWhere -> Delete(..delete, where:)
    XorWhere(conditions:) ->
      Delete(..delete, where: conditions |> list.append([where]) |> XorWhere)
    _ -> Delete(..delete, where: [delete.where, where] |> XorWhere)
  }
}

/// Sets a `NotWhere` or appends into an existing `AndWhere`.
///
/// - Wraps the given `Where` in a `NotWhere`, then applies it with `AND`
///   semantics:
/// - If the query does not have a `Where` clause, the given `Where` is set
///   as a `NotWhere`.
/// - If the outermost `Where` is an `AndWhere`, the new `NotWhere` is appended
///   to the list within `AndWhere`.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
pub fn not_where(delete delete: Delete(a), where where: Where) -> Delete(a) {
  case delete.where {
    NoWhere -> Delete(..delete, where: NotWhere(condition: where))
    AndWhere(conditions:) ->
      Delete(
        ..delete,
        where: conditions
          |> list.append([NotWhere(condition: where)])
          |> AndWhere,
      )
    _ ->
      Delete(
        ..delete,
        where: [delete.where, NotWhere(condition: where)] |> AndWhere,
      )
  }
}

/// Replaces the `Where` in the `Delete` query.
///
pub fn replace_where(
  delete delete: Delete(a),
  where where: Where,
) -> Delete(a) {
  Delete(..delete, where:)
}

/// Removes the `Where` from the `Delete` query.
///
pub fn no_where(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, where: NoWhere)
}

/// Gets the `Where` of the `Delete` query.
///
pub fn get_where(delete delete: Delete(a)) -> Where {
  delete.where
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `Delete` query.
///
pub fn returning(
  delete delete: Delete(a),
  returning returning: List(String),
) -> Delete(a) {
  case returning {
    [] -> Delete(..delete, returning: NoReturning)
    _ -> Delete(..delete, returning: returning |> Returning)
  }
}

/// Specify that no columns should be returned after the `Delete` query.
///
pub fn no_returning(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `Delete` query.
///
pub fn epilog(delete delete: Delete(a), epilog epilog: String) -> Delete(a) {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Delete(..delete, epilog: NoEpilog)
    _ -> Delete(..delete, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `Delete` query.
///
pub fn no_epilog(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, epilog: NoEpilog)
}

/// Get the epilog from a `Delete` query.
///
pub fn get_epilog(delete delete: Delete(a)) -> Epilog {
  delete.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `Delete` query.
///
pub fn comment(delete delete: Delete(a), comment comment: String) -> Delete(a) {
  let comment = comment |> string.trim
  case comment {
    "" -> Delete(..delete, comment: NoComment)
    _ -> Delete(..delete, comment: { " " <> comment } |> Comment)
  }
}

/// Specify that no comment should be added to the `Delete` query.
///
pub fn no_comment(delete delete: Delete(a)) -> Delete(a) {
  Delete(..delete, comment: NoComment)
}

/// Get the comment from a `Delete` query.
///
pub fn get_comment(delete delete: Delete(a)) -> Comment {
  delete.comment
}
