//// A DSL to build `SELECT` queries.
////
//// ## Aliases
////
//// ```gleam
//// import cake/select as s
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
////     A[s.new] --> B[s.from_table / s.from_query]
////     B --> C[s.col / s.select]
////     C --> D[s.join]
////     D --> E[s.where]
////     E --> F[s.group_by / s.having]
////     F --> G[s.order_by_asc / s.order_by_desc]
////     G --> H[s.limit / s.offset]
////     H --> I[s.to_query]
//// ```
////
//// ---
////
//// ## Constructor
////
//// ### `new() -> Select`
////
//// Creates an empty `Select` query. All clauses are unset by default
//// (`SELECT ALL`, no `FROM`, no `WHERE`, etc.).
////
//// ```gleam
//// s.new()
//// ```
////
//// ### `to_query(select: Select) -> ReadQuery`
////
//// Converts a `Select` into a `ReadQuery` suitable for passing to an adapter.
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.to_query
//// ```
////
//// ---
////
//// ## SELECT values
////
//// These functions create `SelectValue`s — the individual expressions that appear
//// between `SELECT` and `FROM`.
////
//// | Function          | SQL equivalent        |
//// | ----------        | ----------            |
//// | `col("table.column")`   | `table.column`        |
//// | `alias(value, "alias")` | `expression AS alias` |
//// | `bool(True)`            | `TRUE` (as param)     |
//// | `float(3.14)`           | `3.14` (as param)     |
//// | `int(42)`               | `42` (as param)       |
//// | `string("hi")`          | `'hi'` (as param)     |
//// | `date(d)`               | date param            |
//// | `null()`                | `NULL`                |
//// | `fragment(f)`           | raw SQL fragment      |
////
//// ### Examples
////
//// ```gleam
//// // Simple column
//// s.col("users.name")
////
//// // Column with alias
//// s.col("users.name") |> s.alias("full_name")
////
//// // Literal integer
//// s.int(1)
////
//// // Fragment-based expression (e.g. database function)
//// import cake/fragment as f
//// s.fragment(f.literal("NOW()"))
//// ```
////
//// ---
////
//// ## Adding columns to the SELECT list
////
//// ### `select_col(select, name) -> Select`
////
//// Appends a bare column name to the projection list.
////
//// ```gleam
//// s.new()
//// |> s.col("id")
//// |> s.col("name")
//// ```
////
//// ### `select(select, select_value) -> Select`
////
//// Appends any `SelectValue` (including aliases and fragments).
////
//// ```gleam
//// s.new()
//// |> s.select(s.col("id") |> s.alias("user_id"))
//// |> s.select(s.fragment(f.literal("COUNT(*)")))
//// ```
////
//// ### `select_cols(select, names) -> Select`
////
//// ### `selects(select, select_values) -> Select`
////
//// Append multiple columns or values at once.
////
//// ```gleam
//// s.new()
//// |> s.select_cols(["id", "name", "email"])
//// ```
////
//// ### Replace variants
////
//// Use the `replace_*` variants to discard any previously added values:
////
//// | Function                             | Effect                             |
//// | ----------                           | ----------                         |
//// | `replace_select_col(select, name)`   | Replace all with one column        |
//// | `replace_select(select, value)`      | Replace all with one value         |
//// | `replace_select_cols(select, names)` | Replace all with a list of columns |
//// | `replace_selects(select, values)`    | Replace all with a list of values  |
////
//// ---
////
//// ## FROM clause
////
//// ### `from_table(select, name) -> Select`
////
//// ```gleam
//// s.new() |> s.from_table("users")
//// // FROM users
//// ```
////
//// ### `from_query(select, sub_query, alias) -> Select`
////
//// Use an aliased sub-query as the source.
////
//// ```gleam
//// let sub =
////   s.new()
////   |> s.from_table("orders")
////   |> s.col("user_id")
////   |> s.to_query
////
//// s.new()
//// |> s.from_query(sub, "recent_orders")
//// |> s.col("user_id")
//// // FROM (SELECT user_id FROM orders) AS recent_orders
//// ```
////
//// ### `no_from(select) -> Select`
////
//// Removes the `FROM` clause (useful for `SELECT 1` style queries).
////
//// ---
////
//// ## SELECT DISTINCT
////
//// ```gleam
//// s.new() |> s.distinct   // SELECT DISTINCT ...
//// s.new() |> s.all        // SELECT ALL ... (default)
//// ```
////
//// ---
////
//// ## JOIN
////
//// See the [`cake/join`](join.md) module for building `Join` values.
////
//// ```mermaid
//// flowchart LR
////     A[j.table / j.sub_query] --> B[j.inner / j.left / j.right / j.full / j.cross]
////     B --> C[s.join]
//// ```
////
//// ### `join(select, join) -> Select`
////
//// Appends a single `Join`.
////
//// ```gleam
//// import cake/join as j
////
//// s.new()
//// |> s.from_table("orders")
//// |> s.join(j.inner(
////   with: j.table("users"),
////   on: w.eq(w.col("orders.user_id"), w.col("users.id")),
////   alias: "users",
//// ))
//// ```
////
//// ### `joins(select, joins) -> Select`
////
//// Appends multiple `Join`s.
////
//// ### Replace / remove variants
////
//// | Function             | Effect                     |
//// | ----------           | ------                     |
//// | `replace_join(select, join)`   | Replace all joins with one |
//// | `replace_joins(select, joins)` | Replace all joins          |
//// | `no_join(select)`              | Remove all joins           |
////
//// ---
////
//// ## WHERE clause
////
//// See [`cake/where`](where.md) for building `Where` values.
////
//// ### `where(select, where) -> Select`
////
//// Adds a condition with `AND` semantics. If the current outermost clause is
//// already an `AndWhere`, the new condition is appended to it.
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.where(w.eq(w.col("active"), w.bool(True)))
//// |> s.where(w.gt(w.col("age"), w.int(18)))
//// // WHERE active = $1 AND age > $2
//// ```
////
//// ### `or_where(select, where) -> Select`
////
//// Combines with `OR` semantics.
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.or_where(w.eq(w.col("role"), w.string("admin")))
//// |> s.or_where(w.eq(w.col("role"), w.string("mod")))
//// // WHERE role = $1 OR role = $2
//// ```
////
//// ### `xor_where(select, where) -> Select`
////
//// Combines with exactly-one-true `XOR` semantics. Implemented via a custom
//// `OR / AND / NOT` expansion on all adapters — native `XOR` is not used on any
//// adapter, including 🦭 MariaDB / 🐬 MySQL.
////
//// > For odd-parity XOR (matching 🦭 MariaDB / 🐬 MySQL native `XOR`), use
//// > `w.xor_parity` instead.
////
//// ### `not_where(select, where) -> Select`
////
//// Negates the given condition with `NOT` and combines with `AND` semantics.
////
//// - If there is no current WHERE, the condition is set as a standalone `NOT`.
//// - If the outermost WHERE is an `AndWhere`, the negated condition is appended to it.
//// - Otherwise, the existing WHERE and the new `NOT` condition are wrapped in an `AndWhere`.
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.where(w.eq(w.col("active"), w.bool(True)))
//// |> s.not_where(w.eq(w.col("role"), w.string("banned")))
//// // WHERE active = $1 AND NOT role = $2
//// ```
////
//// ### Replace / remove variants
////
//// | Function             | Effect                      |
//// | ----------           | ------                      |
//// | `replace_where(select, where)` | Replace entire WHERE clause |
//// | `no_where(select)`             | Remove WHERE clause         |
////
//// ---
////
//// ## GROUP BY / HAVING
////
//// ### `group_by(select, column) -> Select`
////
//// ### `group_bys(select, columns) -> Select`
////
//// ```gleam
//// s.new()
//// |> s.from_table("orders")
//// |> s.col("user_id")
//// |> s.select(s.fragment(f.literal("SUM(amount)")) |> s.alias("total"))
//// |> s.group_by("user_id")
//// // GROUP BY user_id
//// ```
////
//// ### `having(select, where) -> Select`
////
//// ### `or_having(select, where) -> Select`
////
//// ### `xor_having(select, where) -> Select`
////
//// `HAVING` works identically to `WHERE` but filters _after_ aggregation.
//// Build the condition with the same `cake/where` functions.
////
//// ```gleam
//// s.new()
//// |> s.from_table("orders")
//// |> s.group_by("user_id")
//// |> s.having(w.gt(
////   w.fragment_value(f.literal("SUM(amount)")),
////   w.int(100),
//// ))
//// // HAVING SUM(amount) > $1
//// ```
////
//// > **Note:** `cake/having` is a thin placeholder module. Use `cake/where` to
//// > build `Having` conditions — the types are identical.
////
//// ### Replace / remove variants
////
//// | Function                          | Effect                           |
//// | --------------------------------- | -------------------------------- |
//// | `replace_group_by(select, col)`   | Replace GROUP BY with one column |
//// | `replace_group_bys(select, cols)` | Replace GROUP BY with list       |
//// | `no_group_by(select)`             | Remove GROUP BY                  |
//// | `replace_having(select, where)`   | Replace HAVING clause            |
//// | `no_having(select)`               | Remove HAVING clause             |
////
//// ---
////
//// ## ORDER BY
////
//// ```mermaid
//// flowchart LR
////     A[order_by_asc] --> B[ASC]
////     C[order_by_asc_nulls_first] --> D[ASC NULLS FIRST]
////     E[order_by_asc_nulls_last] --> F[ASC NULLS LAST]
////     G[order_by_desc] --> H[DESC]
////     I[order_by_desc_nulls_first] --> J[DESC NULLS FIRST]
////     K[order_by_desc_nulls_last] --> L[DESC NULLS LAST]
//// ```
////
//// | Function                                 | Notes                                  |
//// | ---------------------------------------- | -------------------------------------- |
//// | `order_by_asc(select, col)`              | Append ASC order                       |
//// | `order_by_asc_nulls_first(select, col)`  | Not supported by 🦭 MariaDB / 🐬 MySQL |
//// | `order_by_asc_nulls_last(select, col)`   | Not supported by 🦭 MariaDB / 🐬 MySQL |
//// | `order_by_desc(select, col)`             | Append DESC order                      |
//// | `order_by_desc_nulls_first(select, col)` | Not supported by 🦭 MariaDB / 🐬 MySQL |
//// | `order_by_desc_nulls_last(select, col)`  | Not supported by 🦭 MariaDB / 🐬 MySQL |
//// | `replace_order_by_asc(select, col)`      | Replace all order-bys                  |
//// | `no_order_by(select)`                    | Remove ORDER BY                        |
////
//// ### Custom direction
////
//// ```gleam
//// s.order_by(select, order_by: "name", direction: s.Asc)
//// s.order_by(select, order_by: "created_at", direction: s.Desc)
//// ```
////
//// ---
////
//// ## LIMIT and OFFSET
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.limit(20)
//// |> s.offset(40)
//// // LIMIT 20 OFFSET 40
//// ```
////
//// | Function            | Effect        |
//// | ------------------- | ------------- |
//// | `limit(select, n)`  | Set LIMIT     |
//// | `no_limit(select)`  | Remove LIMIT  |
//// | `offset(select, n)` | Set OFFSET    |
//// | `no_offset(select)` | Remove OFFSET |
////
//// ---
////
//// ## Epilog and Comment
////
//// An **epilog** is appended verbatim to the end of the generated SQL.
//// A **comment** is placed at the very end, typically rendered as a SQL comment.
////
//// ```gleam
//// s.new()
//// |> s.from_table("users")
//// |> s.epilog("FOR UPDATE")
//// |> s.comment("fetching locked rows")
//// // SELECT ... FROM users FOR UPDATE -- fetching locked rows
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/select as s
//// import cake/where as w
//// import cake/join as j
//// import cake/fragment as f
////
//// s.new()
//// |> s.from_table("orders")
//// |> s.select_cols(["orders.id", "users.name"])
//// |> s.select(
////   s.fragment(f.literal("SUM(orders.amount)")) |> s.alias("total"),
//// )
//// |> s.join(j.inner(
////   with: j.table("users"),
////   on: w.eq(w.col("orders.user_id"), w.col("users.id")),
////   alias: "users",
//// ))
//// |> s.where(w.eq(w.col("orders.status"), w.string("paid")))
//// |> s.group_by("orders.id")
//// |> s.group_by("users.name")
//// |> s.having(w.gt(
////   w.fragment_value(f.literal("SUM(orders.amount)")),
////   w.int(0),
//// ))
//// |> s.order_by_desc("total")
//// |> s.limit(5)
//// |> s.to_query
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
  AndWhere, Comment, Epilog, FromSubQuery, FromTable, GroupBy, Joins, NoComment,
  NoEpilog, NoFrom, NoGroupBy, NoJoins, NoLimit, NoOffset, NoOrderBy, NoSelects,
  NoWhere, NotWhere, OrWhere, OrderBy, OrderByColumn, Select, SelectAlias,
  SelectAll, SelectColumn, SelectDistinct, SelectFragment, SelectParam,
  SelectQuery, Selects, XorWhere,
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

pub type Fragment =
  read_query.Fragment

pub type From =
  read_query.From

pub type GroupBy =
  read_query.GroupBy

pub type Join =
  read_query.Join

pub type Joins =
  read_query.Joins

pub type Limit =
  read_query.Limit

pub type Offset =
  read_query.Offset

pub type OrderBy =
  read_query.OrderBy

pub type OrderByDirection =
  read_query.OrderByDirection

pub type ReadQuery =
  read_query.ReadQuery

pub type Select =
  read_query.Select

pub type SelectKind =
  read_query.SelectKind

pub type SelectValue =
  read_query.SelectValue

pub type Selects =
  read_query.Selects

pub type Where =
  read_query.Where

/// Creates a `ReadQuery` from a `Select` query.
///
pub fn to_query(select select: Select) -> ReadQuery {
  select |> SelectQuery
}

/// Creates a column `SelectValue` from a `String`.
///
pub fn col(name name: String) -> SelectValue {
  name |> SelectColumn
}

/// Creates an alias `SelectValue` from `String`.
///
pub fn alias(value value: SelectValue, alias alias: String) -> SelectValue {
  value |> SelectAlias(name: alias)
}

/// Creates a `SelectValue` from a `Bool`.
///
pub fn bool(value value: Bool) -> SelectValue {
  value |> BoolParam |> SelectParam
}

/// Creates a `SelectValue` from a `Float`.
///
pub fn float(value value: Float) -> SelectValue {
  value |> FloatParam |> SelectParam
}

/// Creates a `SelectValue` from an `Int`.
///
pub fn int(value value: Int) -> SelectValue {
  value |> IntParam |> SelectParam
}

/// Creates a `SelectValue` from a `String`.
///
pub fn string(value value: String) -> SelectValue {
  value |> StringParam |> SelectParam
}

/// Creates a `SelectValue` from a `calendar.Date`.
///
pub fn date(v value: calendar.Date) -> SelectValue {
  value |> DateParam |> SelectParam
}

/// Creates an SQL `NULL` `Param`.
///
pub fn null() -> SelectValue {
  NullParam |> SelectParam
}

/// Creates a `SelectFragment` off a `Fragment`.
pub fn fragment(fragment fragment: Fragment) -> SelectValue {
  fragment |> SelectFragment
}

// ▒▒▒ NEW ▒▒▒

/// Creates an empty `Select` query.
///
pub fn new() -> Select {
  Select(
    kind: SelectAll,
    select: NoSelects,
    from: NoFrom,
    join: NoJoins,
    where: NoWhere,
    group_by: NoGroupBy,
    having: NoWhere,
    order_by: NoOrderBy,
    limit: NoLimit,
    offset: NoOffset,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ KIND ▒▒▒

/// Sets the kind of the `Select` query to
/// return duplicates which is the default.
///
pub fn all(select select: Select) -> Select {
  Select(..select, kind: SelectAll)
}

/// Sets the kind of the `Select` query to
/// return distinct rows only.
///
pub fn distinct(select select: Select) -> Select {
  Select(..select, kind: SelectDistinct)
}

/// Gets the kind of the `Select` query.
///
pub fn get_kind(select select: Select) -> SelectKind {
  select.kind
}

// ▒▒▒ FROM ▒▒▒

/// Sets the `FROM` clause of the `Select` query to a table name.
///
pub fn from_table(select select: Select, name table_name: String) -> Select {
  Select(..select, from: table_name |> FromTable)
}

/// Sets the `FROM` clause of the `Select` query to an aliased sub-query.
///
pub fn from_query(
  select select: Select,
  sub_query sub_query: ReadQuery,
  alias alias: String,
) -> Select {
  Select(..select, from: sub_query |> FromSubQuery(alias:))
}

/// Removes the `FROM` clause of the `Select` query.
///
pub fn no_from(select select: Select) -> Select {
  Select(..select, from: NoFrom)
}

/// Gets the `FROM` clause of the `Select` query.
///
pub fn get_from(select select: Select) -> From {
  select.from
}

// ▒▒▒ SELECT ▒▒▒

/// Add a column name to the `Select` query as a `SelectValue`.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select_col(select select: Select, name name: String) -> Select {
  let select_value = name |> col
  case select.select {
    NoSelects -> Select(..select, select: [select_value] |> Selects)
    Selects(values:) ->
      Select(
        ..select,
        select: values
          |> list.append([select_value])
          |> Selects,
      )
  }
}

/// Add a `SelectValue` to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new one is appended.
///
pub fn select(
  select select: Select,
  select_value select_value: SelectValue,
) -> Select {
  case select.select {
    NoSelects -> Select(..select, select: [select_value] |> Selects)
    Selects(values:) ->
      Select(
        ..select,
        select: values
          |> list.append([select_value])
          |> Selects,
      )
  }
}

/// Add a column name to the `Select` query as a `SelectValue`.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select_col(select select: Select, name name: String) -> Select {
  name |> col |> replace_select(select:)
}

/// Add a `SelectValue` to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
pub fn replace_select(
  select select: Select,
  select_value select_value: SelectValue,
) -> Select {
  Select(..select, select: [select_value] |> Selects)
}

/// Adds many column names as `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn select_cols(
  select select: Select,
  select_cols columns: List(String),
) -> Select {
  columns |> list.map(with: col) |> selects(select:)
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are appended.
///
pub fn selects(
  select select: Select,
  select_values select_values: List(SelectValue),
) -> Select {
  case select_values, select.select {
    [], _ -> select
    select_values, NoSelects ->
      Select(..select, select: select_values |> Selects)
    select_values, Selects(existing_selects) ->
      Select(
        ..select,
        select: existing_selects
          |> list.append(select_values)
          |> Selects,
      )
  }
}

/// Adds many column names as `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, the new ones are replaced.
///
pub fn replace_select_cols(
  select select: Select,
  select_cols columns: List(String),
) -> Select {
  columns |> list.map(with: col) |> replace_selects(select:)
}

/// Adds many `SelectValue`s to the `Select` query.
///
/// If the query already has any `SelectValue`s, they are replaced.
///
/// If no `SelectValue`s are provided, the query is returned as-is.
///
pub fn replace_selects(
  select select: Select,
  select_values select_values: List(SelectValue),
) -> Select {
  case select_values {
    [] -> select
    _ -> Select(..select, select: select_values |> Selects)
  }
}

/// Gets the `SelectValue`s of the `Select` query.
///
pub fn get_select(select select: Select) -> Selects {
  select.select
}

// ▒▒▒ JOIN ▒▒▒

/// Adds a `Join` to the `Select` query.
///
pub fn join(select select: Select, join join: Join) -> Select {
  case select.join {
    Joins(items: existing_joins) ->
      Select(..select, join: existing_joins |> list.append([join]) |> Joins)
    NoJoins -> Select(..select, join: [join] |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with a single `Join`.
///
pub fn replace_join(select select: Select, join join: Join) -> Select {
  Select(..select, join: [join] |> Joins)
}

/// Adds `Join`s to the `Select` query.
///
pub fn joins(select select: Select, joins joins: List(Join)) -> Select {
  case joins, select.join {
    [], _ -> select
    _, Joins(items: existing_joins) ->
      Select(..select, join: existing_joins |> list.append(joins) |> Joins)
    _, NoJoins -> Select(..select, join: joins |> Joins)
  }
}

/// Replaces any `Join`s of the `Select` query with the given `Join`s.
///
pub fn replace_joins(select select: Select, joins joins: List(Join)) -> Select {
  Select(..select, join: joins |> Joins)
}

/// Removes any `Joins` from the `Select` query.
///
pub fn no_join(select select: Select) -> Select {
  Select(..select, join: NoJoins)
}

/// Gets the `Joins` of the `Select` query.
///
pub fn get_joins(select select: Select) -> Joins {
  select.join
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
pub fn where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    AndWhere(conditions:) ->
      Select(..select, where: conditions |> list.append([where]) |> AndWhere)
    _ -> Select(..select, where: [select.where, where] |> AndWhere)
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
pub fn or_where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    OrWhere(conditions:) ->
      Select(..select, where: conditions |> list.append([where]) |> OrWhere)
    _ -> Select(..select, where: [select.where, where] |> OrWhere)
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
/// For odd-parity XOR that delegates to 🦭MariaDB / 🐬MySQL native `XOR`,
/// use `where.xor_parity` instead.
///
pub fn xor_where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where:)
    XorWhere(conditions:) ->
      Select(..select, where: conditions |> list.append([where]) |> XorWhere)
    _ -> Select(..select, where: [select.where, where] |> XorWhere)
  }
}

/// Sets a `NotWhere` or appends into an existing `AndWhere`.
///
/// Wraps the given `Where` in a `NotWhere`, then applies it with `AND`
/// semantics:
///
/// - If the query does not have a `Where` clause, the given `Where` is set
///   as a `NotWhere`.
/// - If the outermost `Where` is an `AndWhere`, the new `NotWhere` is appended
///   to the list within `AndWhere`.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
pub fn not_where(select select: Select, where where: Where) -> Select {
  case select.where {
    NoWhere -> Select(..select, where: NotWhere(condition: where))
    AndWhere(conditions:) ->
      Select(
        ..select,
        where: conditions
          |> list.append([NotWhere(condition: where)])
          |> AndWhere,
      )
    _ ->
      Select(
        ..select,
        where: [select.where, NotWhere(condition: where)] |> AndWhere,
      )
  }
}

/// Replaces the `Where` in the `Select` query.
///
pub fn replace_where(select select: Select, where where: Where) -> Select {
  Select(..select, where:)
}

/// Removes the `Where` from the `Select` query.
///
pub fn no_where(select select: Select) -> Select {
  Select(..select, where: NoWhere)
}

/// Gets the `Where` of the `Select` query.
///
pub fn get_where(select select: Select) -> Where {
  select.where
}

// ▒▒▒ HAVING ▒▒▒

/// Sets an `AndWhere` or appends into an existing `AndWhere`.
///
/// - If the outermost `Where` is an `AndWhere`, the new `Where` is appended
///   to the list within `AndWhere`.
/// - If the query does not have a `Where` clause, the given `Where` is set
///   instead.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
/// NOTICE: `HAVING` allows to specify constraints much like `WHERE`, but
/// filters the results after `GROUP BY` is applied instead of before. Because
/// `HAVING` uses the same semantics as `WHERE`, it
///         takes a `Where`.
///
pub fn having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    AndWhere(conditions:) ->
      Select(..select, having: conditions |> list.append([where]) |> AndWhere)
    _ -> Select(..select, having: [select.having, where] |> AndWhere)
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
/// See function `having` on details why this takes a `Where`.
///
pub fn or_having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    OrWhere(conditions:) ->
      Select(..select, having: conditions |> list.append([where]) |> OrWhere)
    _ -> Select(..select, having: [select.having, where] |> OrWhere)
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
/// See function `having` on details why this takes a `Where`.
///
/// NOTICE: *Cake* implements this using a custom `OR / AND / NOT` expansion
/// on all four adapters (🐘PostgreSQL, 🪶SQLite, 🦭MariaDB, 🐬MySQL) —
/// native `XOR` is **not** used on any adapter.
///
/// For odd-parity XOR (which on 🦭MariaDB / 🐬MySQL delegates to its native
/// `XOR`) use `where.xor_parity` instead.
///
pub fn xor_having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: where)
    XorWhere(conditions:) ->
      Select(..select, having: conditions |> list.append([where]) |> XorWhere)
    _ -> Select(..select, having: [select.having, where] |> XorWhere)
  }
}

/// Sets a `NotWhere` or appends into an existing `AndWhere` for `HAVING`.
///
/// - Wraps the given `Where` in a `NotWhere`, then applies it with `AND`
///   semantics:
/// - If the query does not have a `HAVING` clause, the given `Where` is set
///   as a `NotWhere`.
/// - If the outermost `Where` is an `AndWhere`, the new `NotWhere` is appended
///   to the list within `AndWhere`.
/// - If the outermost `Where` is any other kind of `Where`, this and the
///   current outermost `Where` are wrapped in an `AndWhere`.
///
/// See function `having` on details why this takes a `Where`.
///
pub fn not_having(select select: Select, having where: Where) -> Select {
  case select.having {
    NoWhere -> Select(..select, having: NotWhere(condition: where))
    AndWhere(conditions:) ->
      Select(
        ..select,
        having: conditions
          |> list.append([NotWhere(condition: where)])
          |> AndWhere,
      )
    _ ->
      Select(
        ..select,
        having: [select.having, NotWhere(condition: where)] |> AndWhere,
      )
  }
}

/// Replaces `HAVING` in the `Select` query.
///
/// See function `having` on details why this takes a `Where`.
///
pub fn replace_having(select select: Select, having where: Where) -> Select {
  Select(..select, having: where)
}

/// Removes `HAVING` from the `Select` query.
///
pub fn no_having(select select: Select) -> Select {
  Select(..select, having: NoWhere)
}

/// Gets `HAVING` in the `Select` query.
///
/// See function `having` on details why this returns a `Where`.
///
pub fn get_having(select select: Select) -> Where {
  select.having
}

// ▒▒▒ GROUP BY ▒▒▒

/// Sets or appends `GroupBy` a single into an existing `GroupBy`.
///
pub fn group_by(select select: Select, group_by group_by: String) -> Select {
  case select.group_by {
    NoGroupBy -> Select(..select, group_by: [group_by] |> GroupBy)
    GroupBy(columns:) ->
      Select(..select, group_by: columns |> list.append([group_by]) |> GroupBy)
  }
}

/// Replaces `GroupBy` with a single `GroupBy`.
///
pub fn replace_group_by(
  select select: Select,
  group_by group_by: String,
) -> Select {
  Select(..select, group_by: [group_by] |> GroupBy)
}

/// Sets or appends a list of `GroupBy` into an existing `GroupBy`.
///
pub fn group_bys(
  select select: Select,
  group_bys group_bys: List(String),
) -> Select {
  case select.group_by {
    NoGroupBy -> Select(..select, group_by: group_bys |> GroupBy)
    GroupBy(columns:) ->
      Select(
        ..select,
        group_by: columns
          |> list.append(group_bys)
          |> GroupBy,
      )
  }
}

/// Replaces `GroupBy` with a list of `GroupBy`s.
///
pub fn replace_group_bys(
  select select: Select,
  group_bys group_bys: List(String),
) -> Select {
  Select(..select, group_by: group_bys |> GroupBy)
}

/// Removes `GroupBy` from the `Select` query.
///
pub fn no_group_by(select select: Select) -> Select {
  Select(..select, group_by: NoGroupBy)
}

/// Gets `GroupBy` in the `Select` query.
///
pub fn get_group_by(select select: Select) -> GroupBy {
  select.group_by
}

// ▒▒▒ LIMIT & OFFSET ▒▒▒

/// Sets a `Limit` in the `Select` query.
///
pub fn limit(select select: Select, limit limit: Int) -> Select {
  let limit = limit |> read_query.limit_new
  Select(..select, limit:)
}

/// Removes `Limit` from the `Select` query.
///
pub fn no_limit(select select: Select) -> Select {
  Select(..select, limit: NoLimit)
}

/// Gets `Limit` in the `Select` query.
///
pub fn get_limit(select select: Select) -> Limit {
  select.limit
}

/// Sets an `Offset` in the `Select` query.
///
pub fn offset(select select: Select, offset offset: Int) -> Select {
  let offset = offset |> read_query.offset_new
  Select(..select, offset:)
}

/// Removes `Offset` from the `Select` query.
///
pub fn no_offset(select select: Select) -> Select {
  Select(..select, offset: NoOffset)
}

/// Gets `Offset` in the `Select` query.
///
pub fn get_offset(select select: Select) -> Offset {
  select.offset
}

// ▒▒▒ ORDER BY ▒▒▒

// FIXME: This should be reexported from `read_query` once gleam allows it.
//
/// Defines the direction of an `OrderBy`.
///
pub type Direction {
  Asc
  Desc
}

fn map_order_by_direction_constructor(in in: Direction) -> OrderByDirection {
  case in {
    Asc -> read_query.Asc
    Desc -> read_query.Desc
  }
}

/// Creates or appends an ascending `OrderBy`.
///
pub fn order_by_asc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Asc)]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_asc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [
      order_by |> OrderByColumn(direction: read_query.AscNullsFirst),
    ]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends an ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_asc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsLast)]
      |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy`.
///
pub fn replace_order_by_asc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Asc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_asc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single ascending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_asc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.AscNullsLast)]
      |> OrderBy,
    append: False,
  )
}

/// Creates or appends a descending `OrderBy`.
///
pub fn order_by_desc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn order_by_desc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: True,
  )
}

/// Creates or appends a descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn order_by_desc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsLast)]
      |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a single descending order.
///
pub fn replace_order_by_desc(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.Desc)] |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending order with `NULLS FIRST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` out of the box.
///
pub fn replace_order_by_desc_nulls_first(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsFirst)]
      |> OrderBy,
    append: False,
  )
}

/// Replaces the `OrderBy` a single descending `OrderBy` with `NULLS LAST`.
///
/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS LAST` out of the box.
///
pub fn replace_order_by_desc_nulls_last(
  select select: Select,
  order_by order_by: String,
) -> Select {
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction: read_query.DescNullsLast)]
      |> OrderBy,
    append: False,
  )
}

/// Creates or appends an `OrderBy` a column with a direction.
///
/// The direction can either `ASC` or `DESC`.
///
pub fn order_by(
  select select: Select,
  order_by order_by: String,
  direction direction: Direction,
) -> Select {
  let direction = direction |> map_order_by_direction_constructor
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction:)] |> OrderBy,
    append: True,
  )
}

/// Replaces the `OrderBy` a column with a direction.
///
pub fn replace_order_by(
  select select: Select,
  order_by order_by: String,
  direction direction: Direction,
) -> Select {
  let direction = direction |> map_order_by_direction_constructor
  select
  |> read_query.select_order_by(
    order_by: [order_by |> OrderByColumn(direction:)] |> OrderBy,
    append: False,
  )
}

/// Removes the `OrderBy` from the `Select` query.
///
pub fn no_order_by(select select: Select) -> Select {
  Select(..select, order_by: NoOrderBy)
}

/// Gets the `OrderBy` from the `Select` query.
///
pub fn get_order_by(select select: Select) -> OrderBy {
  select.order_by
}

// ▒▒▒ EPILOG ▒▒▒

/// Appends an `Epilog` to the `Select` query.
///
pub fn epilog(select select: Select, epilog epilog: String) -> Select {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Select(..select, epilog: NoEpilog)
    _ -> Select(..select, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Removes the `Epilog` from the `Select` query.
///
pub fn no_epilog(select select: Select) -> Select {
  Select(..select, epilog: NoEpilog)
}

/// Gets the `Epilog` from the `Select` query.
///
pub fn get_epilog(select select: Select) -> Epilog {
  select.epilog
}

// ▒▒▒ COMMENT ▒▒▒

/// Appends a `Comment` to the `Select` query.
///
pub fn comment(select select: Select, comment comment: String) -> Select {
  let comment = comment |> string.trim
  case comment {
    "" -> Select(..select, comment: NoComment)
    _ -> Select(..select, comment: { " " <> comment } |> Comment)
  }
}

/// Removes the `Comment` from the `Select` query.
///
pub fn no_comment(select select: Select) -> Select {
  Select(..select, comment: NoComment)
}

/// Gets the `Comment` from the `Select` query.
///
pub fn get_comment(select select: Select) -> Comment {
  select.comment
}
