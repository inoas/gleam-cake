//// A DSL to build `UPDATE` queries.
////
//// ## Aliases
////
//// ```gleam
//// import cake/update as u
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
////     A[u.new] --> B[u.table]
////     B --> C[u.set / u.sets]
////     C --> D[u.from_table / u.from_sub_query]
////     D --> E[u.join]
////     E --> F[u.where]
////     F --> G[u.returning]
////     G --> H[u.to_query]
//// ```
////
//// ---
////
//// ## Constructor
////
//// ### `new() -> Update(a)`
////
//// Creates an empty `Update` query.
////
//// ### `to_query(update: Update(a)) -> WriteQuery(a)`
////
//// Converts an `Update` into a `WriteQuery` for execution.
////
//// ---
////
//// ## Table
////
//// ### `table(update, name) -> Update(a)`
////
//// Sets the target table for the `UPDATE`.
////
//// ```gleam
//// u.new() |> u.table("users")
//// // UPDATE users SET ...
//// ```
////
//// ---
////
//// ## SET clauses
////
//// Each `UpdateSet` represents one `column = value` assignment. You accumulate
//// sets with `set()` / `sets()`, then Cake renders them as a `SET col = val, ...`
//// clause.
////
//// ### Value setters
////
//// | Function                      | SQL equivalent       |
//// | ----------------------------- | -------------------- |
//// | `set_bool(col, value)`        | `col = TRUE/FALSE`   |
//// | `set_true(col)`               | `col = TRUE`         |
//// | `set_false(col)`              | `col = FALSE`        |
//// | `set_float(col, value)`       | `col = $n` (float)   |
//// | `set_int(col, value)`         | `col = $n` (int)     |
//// | `set_string(col, value)`      | `col = $n` (string)  |
//// | `set_null(col)`               | `col = NULL`         |
//// | `set_date(col, date)`         | `col = $n` (date)    |
//// | `set_expression(col, expr)`   | `col = raw_expr`     |
//// | `set_sub_query(col, query)`   | `col = (SELECT ...)` |
//// | `set_fragment(col, fragment)` | `col = <fragment>`   |
////
//// ```gleam
//// u.new()
//// |> u.table("users")
//// |> u.set(u.set_string("name", "Alice"))
//// |> u.set(u.set_int("age", 31))
//// |> u.set(u.set_null("deleted_at"))
//// // UPDATE users SET name = $1, age = $2, deleted_at = NULL
//// ```
////
//// ### `set_expression(col, expr) -> UpdateSet`
////
//// Injects a raw SQL expression on the right-hand side. Useful for
//// self-referencing updates or database functions.
////
//// ```gleam
//// u.set_expression("score", "score + 10")
//// // score = score + 10
////
//// u.set_expression("updated_at", "NOW()")
//// // updated_at = NOW()
//// ```
////
//// ### `set_fragment(col, fragment) -> UpdateSet`
////
//// Binds a prepared fragment as the RHS. Preferred over `set_expression` when
//// user-controlled values are involved.
////
//// ```gleam
//// import cake/fragment as f
////
//// u.set_fragment(
////   "org_id",
////   f.prepared("?::uuid", [f.string("0000-0000-4000-a000-a00000000000")]),
//// )
//// ```
////
//// ### `set_sub_query(col, query) -> UpdateSet`
////
//// Sets a column to the result of a sub-query.
////
//// ```gleam
//// import cake/select as s
////
//// let sub =
////   s.new()
////   |> s.from_table("profiles")
////   |> s.col("display_name")
////   |> s.where(w.eq(w.col("profiles.user_id"), w.col("users.id")))
////   |> s.to_query
////
//// u.new()
//// |> u.table("users")
//// |> u.set(u.set_sub_query("cached_name", sub))
//// ```
////
//// ### Multi-column setters
////
//// | Function                      | Notes                                    |
//// | ----------------------------- | ---------------------------------------- |
//// | `sets_expression(cols, expr)` | Expression must return same column count |
//// | `sets_sub_query(cols, query)` | Sub-query must return same column count  |
////
//// ### Accumulating vs replacing sets
////
//// | Function                     | Effect                             |
//// | ---------------------------- | ---------------------------------- |
//// | `set(update, set)`           | Append one `UpdateSet`             |
//// | `set_replace(update, set)`   | Replace all with one `UpdateSet`   |
//// | `sets(update, sets)`         | Append many `UpdateSet`s           |
//// | `sets_replace(update, sets)` | Replace all with many `UpdateSet`s |
////
//// ---
////
//// ## FROM clause
////
//// On 🐘 PostgreSQL and 🪶 SQLite an `UPDATE` supports a `FROM` clause to join
//// additional tables for use in `SET` expressions or `WHERE` conditions.
////
//// > 🦭 MariaDB and 🐬 MySQL do not use `FROM` in `UPDATE`; use `JOIN` instead.
////
//// ### `from_table(update, name) -> Update(a)`
////
//// ```gleam
//// u.new()
//// |> u.table("employees")
//// |> u.from_table("departments")
//// |> u.set(u.set_expression("salary", "departments.budget / 10"))
//// |> u.where(w.eq(w.col("employees.dept_id"), w.col("departments.id")))
//// // UPDATE employees SET salary = departments.budget / 10
//// // FROM departments WHERE employees.dept_id = departments.id
//// ```
////
//// ### `from_sub_query(update, query, alias) -> Update(a)`
////
//// Use an aliased sub-query as the `FROM` source.
////
//// ### `no_from(update) -> Update(a)`
////
//// Remove the `FROM` clause.
////
//// ---
////
//// ## JOIN
////
//// On 🦭 MariaDB and 🐬 MySQL `JOIN` is the standard way to reference other
//// tables in an `UPDATE`.
////
//// > On 🐘 PostgreSQL and 🪶 SQLite, `JOIN` is only allowed when a `FROM` clause
//// > is also set.
////
//// ```gleam
//// u.new()
//// |> u.table("orders")
//// |> u.join(j.inner(
////   with: j.table("users"),
////   on: w.eq(w.col("orders.user_id"), w.col("users.id")),
////   alias: "users",
//// ))
//// |> u.set(u.set_expression("orders.status", "'shipped'"))
//// |> u.where(w.eq(w.col("users.tier"), w.string("premium")))
//// ```
////
//// | Function                       | Effect                     |
//// | ------------------------------ | -------------------------- |
//// | `join(update, join)`           | Append one join            |
//// | `replace_join(update, join)`   | Replace all joins with one |
//// | `joins(update, joins)`         | Append many joins          |
//// | `replace_joins(update, joins)` | Replace all joins          |
//// | `no_join(update)`              | Remove all joins           |
////
//// ---
////
//// ## WHERE clause
////
//// See [`cake/where`](where.md) for building `Where` values.
////
//// ### `where(update, where) -> Update(a)`
////
//// Adds a condition with `AND` semantics.
////
//// ```gleam
//// u.new()
//// |> u.table("users")
//// |> u.set(u.set_bool("active", False))
//// |> u.where(w.lt(w.col("last_login"), w.date(cutoff_date)))
//// // UPDATE users SET active = $1 WHERE last_login < $2
//// ```
////
//// ### `or_where(update, where) -> Update(a)`
////
//// Combines with `OR` semantics.
////
//// ### `xor_where(update, where) -> Update(a)`
////
//// Combines with exactly-one-true `XOR` semantics. Implemented via a custom
//// `OR / AND / NOT` expansion on all adapters — native `XOR` is not used on any
//// adapter, including 🦭 MariaDB / 🐬 MySQL.
////
//// > For odd-parity XOR (matching 🦭 MariaDB / 🐬 MySQL native `XOR`), use
//// > `w.xor_parity` instead.
////
//// ### `not_where(update, where) -> Update(a)`
////
//// Negates the given condition with `NOT` and combines with `AND` semantics.
////
//// - If there is no current WHERE, the condition is set as a standalone `NOT`.
//// - If the outermost WHERE is an `AndWhere`, the negated condition is appended to it.
//// - Otherwise, the existing WHERE and the new `NOT` condition are wrapped in an `AndWhere`.
////
//// | Function                       | Effect                   |
//// | ------------------------------ | ------------------------ |
//// | `replace_where(update, where)` | Replace the entire WHERE |
//// | `no_where(update)`             | Remove WHERE clause      |
////
//// ---
////
//// ## RETURNING
////
//// Fetch column values from the updated rows.
////
//// > Only supported by 🐘 PostgreSQL and 🪶 SQLite.
//// > 🦭 MariaDB and 🐬 MySQL do not support `RETURNING` in `UPDATE`.
////
//// ```gleam
//// u.new()
//// |> u.table("users")
//// |> u.set(u.set_int("login_count", 1))
//// |> u.returning(["id", "login_count"])
//// // UPDATE users SET login_count = $1 RETURNING id, login_count
//// ```
////
//// | Function                  | Effect                    |
//// | ------------------------- | ------------------------- |
//// | `returning(update, cols)` | Return the listed columns |
//// | `no_returning(update)`    | Remove RETURNING clause   |
////
//// ---
////
//// ## Epilog and Comment
////
//// ```gleam
//// u.new()
//// |> u.table("sessions")
//// |> u.set(u.set_expression("expires_at", "NOW() + INTERVAL '1 hour'"))
//// |> u.epilog("RETURNING id")
//// |> u.comment("extend active sessions")
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/update as u
//// import cake/where as w
//// import cake/fragment as f
////
//// u.new()
//// |> u.table("products")
//// |> u.sets([
////   u.set_expression("price", "price * 0.9"),
////   u.set_fragment("updated_at", f.literal("NOW()")),
//// ])
//// |> u.where(w.and([
////   w.eq(w.col("category"), w.string("electronics")),
////   w.gt(w.col("stock"), w.int(0)),
//// ]))
//// |> u.returning(["id", "price"])
//// |> u.to_query
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

import cake/fragment.{type Fragment}
import cake/internal/read_query.{
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, Joins, NoComment, NoEpilog,
  NoFrom, NoJoins, NoWhere, NotWhere, OrWhere, XorWhere,
}
import cake/internal/write_query.{
  NoReturning, NoUpdateModifier, NoUpdateSets, NoUpdateTable, Returning, Update,
  UpdateExpressionSet, UpdateFragmentSet, UpdateParamSet, UpdateQuery,
  UpdateSets, UpdateSubQuerySet, UpdateTable,
}
import cake/param.{
  BoolParam, DateParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/list
import gleam/string
import gleam/time/calendar

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

pub type Update(a) =
  write_query.Update(a)

pub type UpdateSet =
  write_query.UpdateSet

pub type UpdateSets =
  write_query.UpdateSets

pub type UpdateTable =
  write_query.UpdateTable

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Creates a `WriteQuery` from an `Update` query.
///
pub fn to_query(update update: Update(a)) -> WriteQuery(a) {
  update |> UpdateQuery
}

// ▒▒▒ Constructor ▒▒▒

/// Creates an empty `Update` query.
///
pub fn new() -> Update(a) {
  Update(
    modifier: NoUpdateModifier,
    table: NoUpdateTable,
    set: NoUpdateSets,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Sets the table of the `Update` query.
///
pub fn table(update update: Update(a), name name: String) -> Update(a) {
  Update(..update, table: name |> UpdateTable)
}

/// Get the table of the `Update` query.
///
pub fn get_table(update update: Update(a)) -> UpdateTable {
  update.table
}

// ▒▒▒ Set ▒▒▒

/// Sets a column to a `Bool` `UpdateParamSet`.
///
pub fn set_bool(column column: String, value value: Bool) -> UpdateSet {
  value |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `True` `UpdateParamSet`.
///
pub fn set_true(column column: String) -> UpdateSet {
  True |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `False` `UpdateParamSet`.
///
pub fn set_false(column column: String) -> UpdateSet {
  False |> BoolParam |> UpdateParamSet(column:)
}

/// Sets a column to a `Float` `UpdateParamSet`.
///
pub fn set_float(column column: String, value value: Float) -> UpdateSet {
  value |> FloatParam |> UpdateParamSet(column:)
}

/// Sets a column to a `Int` `UpdateParamSet`.
///
pub fn set_int(column column: String, value value: Int) -> UpdateSet {
  value |> IntParam |> UpdateParamSet(column:)
}

/// Sets a column to a string `UpdateParamSet`.
///
pub fn set_string(column column: String, value value: String) -> UpdateSet {
  value |> StringParam |> UpdateParamSet(column:)
}

/// Sets a column to an SQL `NULL` `UpdateParamSet`.
///
pub fn set_null(column column: String) -> UpdateSet {
  NullParam |> UpdateParamSet(column:)
}

/// Sets a column to a `calendar.Date` `UpdateParamSet`.
///
pub fn set_date(column column: String, date date: calendar.Date) -> UpdateSet {
  date |> DateParam |> UpdateParamSet(column:)
}

/// Sets a column to an expression value.
///
pub fn set_expression(
  column column: String,
  expression expression: String,
) -> UpdateSet {
  [column] |> UpdateExpressionSet(expression:)
}

/// Sets a column to a sub-query value.
///
pub fn set_sub_query(
  column column: String,
  query query: ReadQuery,
) -> UpdateSet {
  [column] |> UpdateSubQuerySet(query:)
}

/// Sets a column to a fragment value with parameter binding.
///
/// ## Example
///
/// ```gleam
/// import cake/fragment as f
/// import cake/update as u
///
/// "org_id" |> u.set_fragment(f.prepared("$::uuid", [f.string("0000000000-0000-4000-a000-a00000000000")]))
/// ```
///
pub fn set_fragment(column column: String, value value: Fragment) -> UpdateSet {
  UpdateFragmentSet(column:, value:)
}

/// Sets many columns to an expression value.
///
/// NOTICE: the expression must return an equal count of columns.
///
pub fn sets_expression(
  columns columns: List(String),
  expression expression: String,
) -> UpdateSet {
  columns |> UpdateExpressionSet(expression:)
}

/// Sets many columns to a sub-query value.
///
/// NOTICE: the sub-query must return an equal count of columns.
///
pub fn sets_sub_query(
  columns columns: List(String),
  query query: ReadQuery,
) -> UpdateSet {
  columns |> UpdateSubQuerySet(query:)
}

/// Get the `SET`s of the `Update` query.
///
pub fn get_set(update update: Update(a)) -> List(UpdateSet) {
  case update.set {
    NoUpdateSets -> []
    UpdateSets(items:) -> items
  }
}

/// Sets or appends one column set in an `Update` query.
///
pub fn set(update update: Update(a), set set: UpdateSet) -> Update(a) {
  case update.set {
    NoUpdateSets -> Update(..update, set: [set] |> UpdateSets)
    UpdateSets(items:) ->
      Update(..update, set: items |> list.append([set]) |> UpdateSets)
  }
}

/// Sets or replaces one column set in an `Update` query.
///
pub fn set_replace(update update: Update(a), set set: UpdateSet) -> Update(a) {
  Update(..update, set: [set] |> UpdateSets)
}

/// Sets or appends many column sets in an `Update` query.
///
pub fn sets(update update: Update(a), set sets: List(UpdateSet)) -> Update(a) {
  case update.set {
    NoUpdateSets -> Update(..update, set: sets |> UpdateSets)
    UpdateSets(items:) ->
      Update(..update, set: items |> list.append(sets) |> UpdateSets)
  }
}

/// Sets or replaces many column sets in an `Update` query.
///
pub fn sets_replace(
  update update: Update(a),
  sets sets: List(UpdateSet),
) -> Update(a) {
  Update(..update, set: sets |> UpdateSets)
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Update` query to a table name.
///
pub fn from_table(
  update update: Update(a),
  name table_name: String,
) -> Update(a) {
  Update(..update, from: table_name |> FromTable)
}

/// Sets the `FROM` clause of the `Update` query to an aliased sub-query.
///
pub fn from_sub_query(
  update update: Update(a),
  query query: ReadQuery,
  alias alias: String,
) -> Update(a) {
  Update(..update, from: query |> FromSubQuery(alias:))
}

/// Removes the `FROM` clause of the `Update` query.
///
pub fn no_from(update update: Update(a)) -> Update(a) {
  Update(..update, from: NoFrom)
}

/// Gets the `FROM` clause of the `Update` query.
///
pub fn get_from(update update: Update(a)) -> From {
  update.from
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Update` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn join(update update: Update(a), join join: Join) -> Update(a) {
  case update.join {
    Joins(items: existing_joins) ->
      Update(..update, join: existing_joins |> list.append([join]) |> Joins)
    NoJoins -> Update(..update, join: [join] |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with a single `Join`.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_join(update update: Update(a), join join: Join) -> Update(a) {
  Update(..update, join: [join] |> Joins)
}

/// Adds `Join`s to the `Update` query.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn joins(update update: Update(a), joins joins: List(Join)) -> Update(a) {
  case joins, update.join {
    [], _ -> update
    _, Joins(items: existing_joins) ->
      Update(..update, join: existing_joins |> list.append(joins) |> Joins)
    _, NoJoins -> Update(..update, join: joins |> Joins)
  }
}

/// Replaces any `Join`s of the `Update` query with the given `Join`s.
///
/// NOTICE: On 🐘PostgreSQL and 🪶SQLite `Joins` are only allowed if the `FROM`
/// clause is set as well.
///
pub fn replace_joins(
  update update: Update(a),
  joins joins: List(Join),
) -> Update(a) {
  Update(..update, join: joins |> Joins)
}

/// Removes any `Joins` from the `Update` query.
///
pub fn no_join(update update: Update(a)) -> Update(a) {
  Update(..update, join: NoJoins)
}

/// Gets the `Joins` of the `Update` query.
///
pub fn get_joins(update update: Update(a)) -> Joins {
  update.join
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
pub fn where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    AndWhere(conditions:) ->
      Update(..update, where: conditions |> list.append([where]) |> AndWhere)
    _ -> Update(..update, where: [update.where, where] |> AndWhere)
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
pub fn or_where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    OrWhere(conditions:) ->
      Update(..update, where: conditions |> list.append([where]) |> OrWhere)
    _ -> Update(..update, where: [update.where, where] |> OrWhere)
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
pub fn xor_where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where:)
    XorWhere(conditions:) ->
      Update(..update, where: conditions |> list.append([where]) |> XorWhere)
    _ -> Update(..update, where: [update.where, where] |> XorWhere)
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
pub fn not_where(update update: Update(a), where where: Where) -> Update(a) {
  case update.where {
    NoWhere -> Update(..update, where: NotWhere(condition: where))
    AndWhere(conditions:) ->
      Update(
        ..update,
        where: conditions
          |> list.append([NotWhere(condition: where)])
          |> AndWhere,
      )
    _ ->
      Update(
        ..update,
        where: [update.where, NotWhere(condition: where)] |> AndWhere,
      )
  }
}

/// Replaces the `Where` in the `Update` query.
///
pub fn replace_where(
  update update: Update(a),
  where where: Where,
) -> Update(a) {
  Update(..update, where:)
}

/// Removes the `Where` from the `Update` query.
///
pub fn no_where(update update: Update(a)) -> Update(a) {
  Update(..update, where: NoWhere)
}

/// Gets the `Where` of the `Update` query.
///
pub fn get_where(update update: Update(a)) -> Where {
  update.where
}

// ▒▒▒ RETURNING ▒▒▒

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `RETURNING` in `UPDATE`
/// queries; they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn returning(
  update update: Update(a),
  returning returning: List(String),
) -> Update(a) {
  case returning {
    [] -> Update(..update, returning: NoReturning)
    _ -> Update(..update, returning: returning |> Returning)
  }
}

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `RETURNING` in `UPDATE`
/// queries; they do support it in `INSERT` (and `REPLACE`) queries, however.
///
pub fn no_returning(update update: Update(a)) -> Update(a) {
  Update(..update, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Sets an `Epilog` or appends into an existing `Epilog`.
///
pub fn epilog(update update: Update(a), epilog epilog: String) -> Update(a) {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Update(..update, epilog: NoEpilog)
    _ -> Update(..update, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Update` query.
///
pub fn no_epilog(update update: Update(a)) -> Update(a) {
  Update(..update, epilog: NoEpilog)
}

/// Gets the `Epilog` of the `Update` query.
///
pub fn get_epilog(update update: Update(a)) -> Epilog {
  update.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Sets a `Comment` or appends into an existing `Comment`.
///
pub fn comment(update update: Update(a), comment comment: String) -> Update(a) {
  let comment = comment |> string.trim
  case comment {
    "" -> Update(..update, comment: NoComment)
    _ -> Update(..update, comment: { " " <> comment } |> Comment)
  }
}

/// Removes the `Comment` from the `Update` query.
///
pub fn no_comment(update update: Update(a)) -> Update(a) {
  Update(..update, comment: NoComment)
}

/// Gets the `Comment` of the `Update` query.
///
pub fn get_comment(update update: Update(a)) -> Comment {
  update.comment
}
