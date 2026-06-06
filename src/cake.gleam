//// *Cake* is an SQL query building library for RDBMS:
////
//// - 🐘PostgreSQL
//// - 🪶SQLite
//// - 🦭MariaDB
//// - 🐬MySQL
////
//// For examples see the tests.
////
//// ## Summary
////
//// Cake is a composable SQL query-building library for [Gleam](https://gleam.run). It targets four major RDBMS dialects — 🐘 PostgreSQL, 🪶 SQLite, 🦭 MariaDB, and 🐬 MySQL — and produces **prepared statements** (parameterised SQL + typed parameter lists) that are safe from SQL injection. Cake does _not_ execute queries or decode result rows; it hands a `PreparedStatement` to a dialect adapter library that does so.
////
//// ---
////
//// ## Module Overview
////
//// | Module                         | Alias | Purpose                           |
//// | ------------------------------ | ----- | --------------------------------- |
//// | [`cake/select`](api/select.md)     | `s`   | `SELECT` queries                  |
//// | [`cake/insert`](api/insert.md)     | `i`   | `INSERT` queries                  |
//// | [`cake/update`](api/update.md)     | `u`   | `UPDATE` queries                  |
//// | [`cake/delete`](api/delete.md)     | `d`   | `DELETE` queries                  |
//// | [`cake/combined`](api/combined.md) | `c`   | `UNION` / `EXCEPT` / `INTERSECT`  |
//// | [`cake/where`](api/where.md)       | `w`   | `WHERE` / `HAVING` conditions     |
//// | [`cake/join`](api/join.md)         | `j`   | `JOIN` clauses                    |
//// | [`cake/fragment`](api/fragment.md) | `f`   | Raw SQL fragments (safe & unsafe) |
//// | [`cake/param`](api/param.md)       | `p`   | Typed parameter values            |
////
//// Dialect helpers live under `cake/dialect/`:
////
//// | Module                          | Dialect       |
//// | ------------------------------- | ------------- |
//// | `cake/dialect/postgres_dialect` | 🐘 PostgreSQL |
//// | `cake/dialect/sqlite_dialect`   | 🪶 SQLite     |
//// | `cake/dialect/maria_dialect`    | 🦭 MariaDB    |
//// | `cake/dialect/mysql_dialect`    | 🐬 MySQL      |
////
//// ---
////
//// ## Recommended Imports
////
//// ```gleam
//// import cake
//// import cake/select as s
//// import cake/insert as i
//// import cake/update as u
//// import cake/delete as d
//// import cake/combined as c
//// import cake/where as w
//// import cake/join as j
//// import cake/fragment as f
//// import cake/param as p
//// ```
////
//// ## Query Flow
////
//// Every query is built using a pipeline of builder functions that accumulate
//// clauses, then converted to a `ReadQuery` or `WriteQuery` for execution via
//// your chosen adapter.
////
//// ```mermaid
//// flowchart TD
////     A[new] --> B[add clauses]
////     B --> C[to_query]
////     C --> D{query type}
////     D -->|ReadQuery| E[adapter: run_read_query]
////     D -->|WriteQuery| F[adapter: run_write_query]
////     E --> G[decode results]
////     F --> H[inspect returning / rows affected]
//// ```
////
//// ## Quick Example
////
//// ```gleam
//// import cake/select as s
//// import cake/where as w
////
//// s.new()
//// |> s.from_table("users")
//// |> s.col("id")
//// |> s.col("name")
//// |> s.where(w.eq(w.col("active"), w.bool(True)))
//// |> s.order_by_asc("name")
//// |> s.limit(10)
//// |> s.to_query
//// ```
////
//// Generates:
////
//// ```sql
//// SELECT id, name FROM users WHERE active = $1 ORDER BY name ASC LIMIT 10
//// ```
////
//// ---
////
//// ## How It Works
////
//// ```
//// Build query  →  call to_query()  →  call to_prepared_statement()  →  pass to adapter
//// ```
////
//// 1. **Build** – use one of the query-builder modules (`select`, `insert`, `update`, `delete`, `combined`) to assemble a typed query value.
//// 2. **Compile** – call `cake.to_prepared_statement(query, dialect)` (or the dialect-specific helper) to get a `PreparedStatement`.
//// 3. **Execute** – extract `cake.get_sql(ps)` and `cake.get_params(ps)` and pass them to the appropriate adapter.
////
//// ---
////
//// ## `cake` — Core
////
//// Key types re-exported for adapter use:
////
//// | Type                | Description                                   |
//// | ------------------- | --------------------------------------------- |
//// | `CakeQuery(a)`      | Union of `CakeReadQuery` and `CakeWriteQuery` |
//// | `ReadQuery`         | Any read query (SELECT, combined)             |
//// | `WriteQuery(a)`     | Any write query (INSERT, UPDATE, DELETE)      |
//// | `PreparedStatement` | Compiled SQL string + parameter list          |
//// | `Dialect`           | Target database dialect                       |
//// | `Param`             | Typed query parameter                         |
////
//// Key functions:
////
//// | Function                                            | Description                                          |
//// | --------------------------------------------------- | ---------------------------------------------------- |
//// | `to_read_query(query)`                              | Wrap a `ReadQuery` as a `CakeQuery`                  |
//// | `to_write_query(query)`                             | Wrap a `WriteQuery` as a `CakeQuery`                 |
//// | `to_prepared_statement(query, dialect)`             | Compile a `CakeQuery` to a `PreparedStatement`       |
//// | `read_query_to_prepared_statement(query, dialect)`  | Compile a `ReadQuery` directly                       |
//// | `write_query_to_prepared_statement(query, dialect)` | Compile a `WriteQuery` directly                      |
//// | `get_sql(ps)`                                       | Extract the SQL string from a `PreparedStatement`    |
//// | `get_params(ps)`                                    | Extract the `List(Param)` from a `PreparedStatement` |
////
//// ---
////
//// ## `cake/select` — SELECT Queries
////
//// Build `SELECT` statements. All builder functions return a new `Select`, making them pipeable.
////
//// ### Constructors
////
//// | Function           | Description            |
//// | ------------------ | ---------------------- |
//// | `new()`            | Empty select query     |
//// | `to_query(select)` | Convert to `ReadQuery` |
////
//// ### Column selection
////
//// | Function                                                                     | Description                           |
//// | ---------------------------------------------------------------------------- | ------------------------------------- |
//// | `col(name)`                                                                  | Reference a column by name            |
//// | `alias(value, alias)`                                                        | Alias a select value                  |
//// | `bool/float/int/string/date/null/fragment(...)`                              | Literal select values                 |
//// | `select_col(query, col)`                                                     | Append a single column                |
//// | `select(query, value)`                                                       | Append a `SelectValue`                |
//// | `selects(query, values)`                                                     | Append multiple `SelectValue`s        |
//// | `replace_select_col/replace_select/replace_select_cols/replace_selects(...)` | Replace current selection             |
//// | `all(query)` / `distinct(query)`                                             | Set `SELECT ALL` or `SELECT DISTINCT` |
////
//// ### FROM clause
////
//// | Function                             | Description                |
//// | ------------------------------------ | -------------------------- |
//// | `from_table(query, name)`            | `FROM table_name`          |
//// | `from_query(query, subquery, alias)` | `FROM (subquery) AS alias` |
//// | `no_from(query)`                     | Remove FROM clause         |
////
//// ### Filtering
////
//// | Function                          | Description              |
//// | --------------------------------- | ------------------------ |
//// | `where(query, condition)`         | Append to `AND WHERE`    |
//// | `or_where(query, condition)`      | Append to `OR WHERE`     |
//// | `xor_where(query, condition)`     | Append to `XOR WHERE`    |
//// | `not_where(query, condition)`     | Append negated condition |
//// | `replace_where(query, condition)` | Replace entire WHERE     |
//// | `no_where(query)`                 | Remove WHERE clause      |
////
//// ### Aggregation
////
//// | Function                                          | Description              |
//// | ------------------------------------------------- | ------------------------ |
//// | `group_by(query, col)` / `group_bys(query, cols)` | Add `GROUP BY` columns   |
//// | `having(query, condition)`                        | Append to `AND HAVING`   |
//// | `or_having / xor_having / not_having(...)`        | Other HAVING combinators |
//// | `replace_having / no_having(...)`                 | Replace or remove HAVING |
////
//// ### Joins
////
//// | Function                                      | Description             |
//// | --------------------------------------------- | ----------------------- |
//// | `join(query, join)`                           | Append a join           |
//// | `joins(query, joins)`                         | Append multiple joins   |
//// | `replace_join / replace_joins / no_join(...)` | Replace or remove joins |
////
//// ### Ordering, paging, extras
////
//// | Function                                                              | Description                       |
//// | --------------------------------------------------------------------- | --------------------------------- |
//// | `order_by_asc / order_by_desc(query, col)`                            | Append ascending/descending order |
//// | `order_by_asc_nulls_first/last / order_by_desc_nulls_first/last(...)` | Order with NULL placement         |
//// | `replace_order_by_* / no_order_by(...)`                               | Replace or remove ORDER BY        |
//// | `limit(query, n)` / `no_limit(query)`                                 | Set or clear LIMIT                |
//// | `offset(query, n)` / `no_offset(query)`                               | Set or clear OFFSET               |
//// | `epilog(query, sql)` / `no_epilog(query)`                             | Append raw SQL after the query    |
//// | `comment(query, text)` / `no_comment(query)`                          | Attach an SQL comment             |
////
//// ---
////
//// ## `cake/insert` — INSERT Queries
////
//// ### Constructors
////
//// | Function                                         | Description                        |
//// | ------------------------------------------------ | ---------------------------------- |
//// | `new()`                                          | Empty insert query                 |
//// | `from_records(table, columns, records, encoder)` | Build from a list of Gleam records |
//// | `from_values(table, columns, rows)`              | Build from a list of `InsertRow`s  |
//// | `to_query(insert)`                               | Convert to `WriteQuery`            |
////
//// ### Row / value helpers
////
//// | Function                                        | Description                 |
//// | ----------------------------------------------- | --------------------------- |
//// | `row(values)`                                   | Create an `InsertRow`       |
//// | `bool/float/int/string/null/date/fragment(...)` | Create typed `InsertValue`s |
////
//// ### Configuration
////
//// | Function                                            | Description                              |
//// | --------------------------------------------------- | ---------------------------------------- |
//// | `table(insert, name)`                               | Set the target table                     |
//// | `columns(insert, cols)`                             | Set column names                         |
//// | `source_records / source_values(...)`               | Change the data source                   |
//// | `modifier(insert, keyword)` / `no_modifier(insert)` | Set a query modifier (e.g. `OR REPLACE`) |
////
//// ### Conflict handling (upsert)
////
//// | Function                                                           | Description                              |
//// | ------------------------------------------------------------------ | ---------------------------------------- |
//// | `on_conflict_error(insert)`                                        | Error on conflict (default)              |
//// | `on_columns_conflict_ignore(insert, cols, where)`                  | Ignore on column conflict (🐘 / 🪶)      |
//// | `on_constraint_conflict_ignore(insert, constraint, where)`         | Ignore on named constraint conflict (🐘) |
//// | `on_columns_conflict_update(insert, cols, where, update)`          | Upsert by columns (🐘 / 🪶)              |
//// | `on_constraint_conflict_update(insert, constraint, where, update)` | Upsert by constraint (🐘)                |
//// | `on_duplicate_key_update(insert, update)`                          | `ON DUPLICATE KEY UPDATE` (🦭 / 🐬)      |
////
//// ### Returning / extras
////
//// | Function                                           | Description                  |
//// | -------------------------------------------------- | ---------------------------- |
//// | `returning(insert, cols)` / `no_returning(insert)` | `RETURNING` clause (🐘 / 🪶) |
//// | `epilog / no_epilog / comment / no_comment(...)`   | Raw SQL epilog and comment   |
////
//// ---
////
//// ## `cake/update` — UPDATE Queries
////
//// ### Constructor
////
//// | Function           | Description             |
//// | ------------------ | ----------------------- |
//// | `new()`            | Empty update query      |
//// | `to_query(update)` | Convert to `WriteQuery` |
////
//// ### SET clause
////
//// | Function                                                                 | Description                                |
//// | ------------------------------------------------------------------------ | ------------------------------------------ |
//// | `set_bool/set_float/set_int/set_string/set_null/set_date(column, value)` | Typed column assignments                   |
//// | `set_true / set_false(column)`                                           | Boolean shorthand                          |
//// | `set_expression(column, expr)`                                           | Raw SQL expression assignment              |
//// | `set_sub_query(column, query)`                                           | Sub-query assignment                       |
//// | `set_fragment(column, fragment)`                                         | Fragment assignment with parameter binding |
//// | `sets_expression / sets_sub_query(columns, ...)`                         | Multi-column assignment                    |
//// | `set(update, set)` / `sets(update, sets)`                                | Append one or more `UpdateSet`s            |
//// | `set_replace / sets_replace(...)`                                        | Replace all SET items                      |
////
//// ### FROM, JOIN, WHERE, RETURNING, extras
////
//// Same API shape as `cake/select` — `from_table`, `from_sub_query`, `no_from`, `join`, `where`, `or_where`, `xor_where`, `not_where`, `replace_where`, `no_where`, `returning`, `no_returning`, `epilog`, `comment`, etc.
////
//// > **Note:** `RETURNING` is not supported on 🦭 MariaDB or 🐬 MySQL for `UPDATE`.
////
//// ---
////
//// ## `cake/delete` — DELETE Queries
////
//// ### Constructor
////
//// | Function           | Description             |
//// | ------------------ | ----------------------- |
//// | `new()`            | Empty delete query      |
//// | `to_query(delete)` | Convert to `WriteQuery` |
////
//// ### Configuration
////
//// | Function                                                        | Description                                           |
//// | --------------------------------------------------------------- | ----------------------------------------------------- |
//// | `table(delete, name)`                                           | Set the table to delete from                          |
//// | `modifier(delete, keyword)` / `no_modifier(delete)`             | Optional modifier                                     |
//// | `using_table / using_sub_query(...)`                            | `USING` clause for multi-table deletes (🐘 / 🦭 / 🐬) |
//// | `replace_using_table / replace_using_sub_query / no_using(...)` | Replace or remove USING                               |
////
//// ### JOIN, WHERE, RETURNING, extras
////
//// Same API shape as `cake/update` — `join`, `where`, `or_where`, `xor_where`, `not_where`, `replace_where`, `no_where`, `returning`, `no_returning`, `epilog`, `comment`, etc.
////
//// > **Note:** 🪶 SQLite does not support `USING`. `RETURNING` is not supported on 🦭 MariaDB or 🐬 MySQL for `DELETE`.
////
//// ---
////
//// ## `cake/combined` — UNION / EXCEPT / INTERSECT
////
//// Combines two or more `Select` queries.
////
//// | Function                                             | Description                     |
//// | ---------------------------------------------------- | ------------------------------- |
//// | `union(a, b)` / `unions(a, b, rest)`                 | `UNION` (distinct)              |
//// | `union_all(a, b)` / `unions_all(a, b, rest)`         | `UNION ALL`                     |
//// | `except(a, b)` / `excepts(a, b, rest)`               | `EXCEPT` (distinct)             |
//// | `except_all(a, b)` / `excepts_all(a, b, rest)`       | `EXCEPT ALL` (not 🪶 SQLite)    |
//// | `intersect(a, b)` / `intersects(a, b, rest)`         | `INTERSECT` (distinct)          |
//// | `intersect_all(a, b)` / `intersects_all(a, b, rest)` | `INTERSECT ALL` (not 🪶 SQLite) |
//// | `to_query(combined)`                                 | Convert to `ReadQuery`          |
////
//// Supports `limit`, `offset`, `order_by_*`, `epilog`, and `comment` with the same API as `cake/select`.
////
//// ---
////
//// ## `cake/where` — WHERE / HAVING Conditions
////
//// Used to build `WHERE` clauses (and `HAVING` clauses, which share the same type).
////
//// ### Value constructors
////
//// | Function                                 | Description            |
//// | ---------------------------------------- | ---------------------- |
//// | `col(name)`                              | Reference a column     |
//// | `bool/float/int/string/null/date(value)` | Typed literal values   |
//// | `true()` / `false()`                     | Boolean shortcuts      |
//// | `sub_query(query)`                       | Scalar sub-query value |
//// | `fragment_value(fragment)`               | Fragment value         |
////
//// ### Logical combinators
////
//// | Function             | Description                                     |
//// | -------------------- | ----------------------------------------------- |
//// | `and(wheres)`        | `AND` of a list of conditions                   |
//// | `or(wheres)`         | `OR` of a list of conditions                    |
//// | `xor(wheres)`        | Strict `XOR` — exactly one true                 |
//// | `xor_parity(wheres)` | Odd-parity `XOR` — uses native `XOR` on 🦭 / 🐬 |
//// | `not(where)`         | Negate a condition                              |
//// | `none()`             | No condition (`NoWhere`)                        |
////
//// ### Comparisons
////
//// `eq`, `neq`, `lt`, `lte`, `gt`, `gte` — compare two `WhereValue`s.
////
//// `eq_any_query`, `lt_any_query`, `lte_any_query`, `gt_any_query`, `gte_any_query`, `neq_any_query` — compare against `ANY` result of a sub-query (not 🪶 SQLite).
////
//// `eq_all_query`, `lt_all_query`, `lte_all_query`, `gt_all_query`, `gte_all_query`, `neq_all_query` — compare against `ALL` results of a sub-query (not 🪶 SQLite).
////
//// ### Other predicates
////
//// | Function                                                 | Description                      |
//// | -------------------------------------------------------- | -------------------------------- |
//// | `is_null / is_not_null(value)`                           | NULL checks                      |
//// | `is_bool / is_not_bool / is_true / is_false(value, ...)` | Boolean checks                   |
//// | `in(value, values)`                                      | `IN (...)` with a list of values |
//// | `in_query(value, query)`                                 | `IN (subquery)`                  |
//// | `exists_in_query(query)`                                 | `EXISTS (subquery)`              |
//// | `between(a, b, c)`                                       | `BETWEEN b AND c`                |
//// | `like(value, pattern)`                                   | `LIKE` pattern match             |
//// | `ilike(value, pattern)`                                  | Case-insensitive `LIKE`          |
//// | `similar_to(value, pattern, escape)`                     | `SIMILAR TO` (not 🪶 SQLite)     |
//// | `fragment(fragment)`                                     | Raw SQL condition                |
////
//// ---
////
//// ## `cake/join` — JOIN Clauses
////
//// ### Join target constructors
////
//// | Function           | Description          |
//// | ------------------ | -------------------- |
//// | `table(name)`      | Join a table by name |
//// | `sub_query(query)` | Join a sub-query     |
////
//// ### Join kind constructors
////
//// | Function                     | Description                                       |
//// | ---------------------------- | ------------------------------------------------- |
//// | `inner(with, on, alias)`     | `INNER JOIN`                                      |
//// | `left(with, on, alias)`      | `LEFT JOIN`                                       |
//// | `right(with, on, alias)`     | `RIGHT JOIN`                                      |
//// | `full(with, on, alias)`      | `FULL JOIN`                                       |
//// | `cross(with, alias)`         | `CROSS JOIN`                                      |
//// | `inner_lateral(with, alias)` | `INNER JOIN LATERAL ... ON TRUE` (🐘 / recent 🐬) |
//// | `left_lateral(with, alias)`  | `LEFT JOIN LATERAL ... ON TRUE` (🐘 / recent 🐬)  |
//// | `cross_lateral(with, alias)` | `CROSS JOIN LATERAL` (🐘 / recent 🐬)             |
////
//// ---
////
//// ## `cake/fragment` — Raw SQL Fragments
////
//// Fragments allow injecting custom SQL into a query while keeping parameter binding safe.
////
//// | Function / Constant                                 | Description                                                          |
//// | --------------------------------------------------- | -------------------------------------------------------------------- |
//// | `placeholder`                                       | The placeholder grapheme used in prepared fragments (`?` by default) |
//// | `prepared(sql, params)`                             | Create a fragment with bound parameters — **safe for user input**    |
//// | `literal(sql)`                                      | Create a fragment from a raw string — **never use with user input**  |
//// | `bool/float/int/string/null/date/true/false(value)` | Convenience `Param` constructors mirroring `cake/param`              |
////
//// ---
////
//// ## `cake/param` — Typed Parameters
////
//// `Param` is the boxed value type used in prepared statements.
////
//// | Constructor / Function                 | Description     |
//// | -------------------------------------- | --------------- |
//// | `StringParam(value)` / `string(value)` | UTF-8 string    |
//// | `IntParam(value)` / `int(value)`       | Integer         |
//// | `FloatParam(value)` / `float(value)`   | Float           |
//// | `BoolParam(value)` / `bool(value)`     | Boolean         |
//// | `NullParam` / `null()`                 | SQL NULL        |
//// | `DateParam(value)` / `date(value)`     | `calendar.Date` |
////
//// ---
////
//// ## Dialect Compatibility Summary
////
//// | Feature                                | 🐘 PostgreSQL | 🪶 SQLite | 🦭 MariaDB | 🐬 MySQL    |
//// | -------------------------------------- | ------------- | --------- | ---------- | ----------- |
//// | `ANY` / `ALL` sub-query                | ✅            | ❌        | ✅         | ✅          |
//// | `SIMILAR TO`                           | ✅            | ❌        | ✅         | ✅          |
//// | `EXCEPT ALL` / `INTERSECT ALL`         | ✅            | ❌        | ✅         | ✅          |
//// | `ON CONFLICT ... DO UPDATE`            | ✅            | ✅        | ❌         | ❌          |
//// | `ON DUPLICATE KEY UPDATE`              | ❌            | ❌        | ✅         | ✅          |
//// | `RETURNING` (INSERT / UPDATE / DELETE) | ✅            | ✅        | ❌         | ❌          |
//// | `USING` in DELETE                      | ✅            | ❌        | ✅         | ✅          |
//// | `LATERAL` joins                        | ✅            | ❌        | ❌         | ✅ (recent) |
//// | `NULLS FIRST` / `NULLS LAST`           | ✅            | ✅        | ❌         | ❌          |
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

import cake/internal/dialect
import cake/internal/prepared_statement
import cake/internal/read_query
import cake/internal/write_query
import cake/param.{type Param}
import gleam/io

pub type ReadQuery =
  read_query.ReadQuery

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

pub type Dialect =
  dialect.Dialect

pub type PreparedStatement =
  prepared_statement.PreparedStatement

/// Base wrapper query type to be able to pass around read and write queries in
/// the same way.
///
pub type CakeQuery(a) {
  CakeReadQuery(query: ReadQuery)
  CakeWriteQuery(query: WriteQuery(a))
}

/// Create a Cake read query from a read query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_read_query(query query: ReadQuery) -> CakeQuery(a) {
  query |> CakeReadQuery
}

/// Create a Cake write query from a write query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_write_query(query query: WriteQuery(a)) -> CakeQuery(a) {
  query |> CakeWriteQuery
}

/// Create a prepared statement from a Cake query.
///
/// Also see `cake/dialect/*` for dialect specific implementations of this.
///
pub fn to_prepared_statement(
  query query: CakeQuery(a),
  dialect dialect: Dialect,
) -> PreparedStatement {
  case query {
    CakeReadQuery(query:) ->
      query
      |> read_query_to_prepared_statement(dialect:)
    CakeWriteQuery(query:) ->
      query
      |> write_query_to_prepared_statement(dialect:)
  }
}

/// Create a prepared statement from a read query.
///
pub fn read_query_to_prepared_statement(
  query query: ReadQuery,
  dialect dialect: Dialect,
) -> PreparedStatement {
  dialect
  |> dialect.placeholder_base
  |> read_query.to_prepared_statement(query:, dialect:)
}

/// Create a prepared statement from a write query.
///
pub fn write_query_to_prepared_statement(
  query query: WriteQuery(a),
  dialect dialect: Dialect,
) -> PreparedStatement {
  dialect
  |> dialect.placeholder_base
  |> write_query.to_prepared_statement(query:, dialect:)
}

/// Get the SQL of the prepared statement.
///
pub fn get_sql(
  prepared_statement prepared_statement: PreparedStatement,
) -> String {
  prepared_statement |> prepared_statement.get_sql
}

/// Get the parameters of the prepared statement.
///
pub fn get_params(
  prepared_statement prepared_statement: PreparedStatement,
) -> List(Param) {
  prepared_statement |> prepared_statement.get_params
}

/// As a library *Cake* cannot be invoked directly in a meaningful way.
///
pub fn main() {
  {
    "\n"
    <> "cake is a query building library and cannot be invoked directly."
    <> "\n"
    <> "For demos see the tests."
  }
  |> io.println
}
