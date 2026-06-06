//// A DSL to build `INSERT` queries.
////
//// ## Aliases
////
//// ```gleam
//// import cake/insert as i
//// import cake/where as w
//// import cake/fragment as f
//// ```
////
//// ---
////
//// ## Query Lifecycle
////
//// ```mermaid
//// flowchart LR
////     A[i.from_records / i.from_values / i.new] --> B[configure table & columns]
////     B --> C[on_conflict strategy]
////     C --> D[returning]
////     D --> E[i.to_query]
//// ```
////
//// ---
////
//// ## Constructors
////
//// There are three ways to start building an `INSERT` query.
////
//// ### `from_records(table_name, columns, records, encoder) -> Insert(a)`
////
//// The idiomatic way. Supply a list of typed Gleam records and an encoder function
//// that maps each record to an `InsertRow`.
////
//// ```gleam
//// type User {
////   User(name: String, age: Int)
//// }
////
//// fn encode_user(u: User) -> i.InsertRow {
////   i.row([i.string(u.name), i.int(u.age)])
//// }
////
//// [User("Alice", 30), User("Bob", 25)]
//// |> i.from_records(
////   table_name: "users",
////   columns: ["name", "age"],
////   encoder: encode_user,
//// )
//// |> i.to_query
//// // INSERT INTO users (name, age) VALUES ($1, $2), ($3, $4)
//// ```
////
//// ### `from_values(table_name, columns, values) -> Insert(a)`
////
//// Supply pre-built `InsertRow` values directly.
////
//// ```gleam
//// [
////   i.row([i.string("Alice"), i.int(30)]),
////   i.row([i.string("Bob"), i.int(25)]),
//// ]
//// |> i.from_values(table_name: "users", columns: ["name", "age"])
//// |> i.to_query
//// ```
////
//// ### `new() -> Insert(a)`
////
//// Creates a completely empty `Insert`. Useful when building the query
//// incrementally.
////
//// ```gleam
//// i.new()
//// |> i.table("users")
//// |> i.columns(["name", "age"])
//// |> i.source_values([i.row([i.string("Alice"), i.int(30)])])
//// |> i.to_query
//// ```
////
//// ### `to_query(insert: Insert(a)) -> WriteQuery(a)`
////
//// Converts an `Insert` into a `WriteQuery` for execution.
////
//// ---
////
//// ## Row and Value Constructors
////
//// ### `row(values: List(InsertValue)) -> InsertRow`
////
//// Wraps a list of `InsertValue`s into a single `InsertRow`.
////
//// ```gleam
//// i.row([i.string("Alice"), i.int(30), i.bool(True)])
//// ```
////
//// ### Value constructors
////
//// | Function          | SQL type         |
////
//// | Function        | SQL type         |
//// | ----------      | ---------------- |
//// | `bool(value)`     | Boolean param    |
//// | `float(value)`    | Float param      |
//// | `int(value)`      | Integer param    |
//// | `string(value)`   | String param     |
//// | `null()`          | NULL             |
//// | `date(value)`     | Date param       |
//// | `fragment(value)` | Raw SQL fragment |
////
//// ```gleam
//// // Inserting a UUID via a database cast
//// import cake/fragment as f
////
//// i.fragment(f.prepared("?::uuid", [f.string("0000-0000-4000-a000-a00000000000")]))
//// ```
////
//// ---
////
//// ## Setting the Table
////
//// When using `new()` you can configure (or override) the target table:
////
//// ```gleam
//// i.new() |> i.table("users")
//// ```
////
//// ---
////
//// ## Configuring the Source
////
//// ### `source_records(insert, records, encoder) -> Insert(a)`
////
//// Attach a list of records and an encoder to an existing `Insert`.
////
//// ### `source_values(insert, rows) -> Insert(a)`
////
//// Attach raw `InsertRow` values to an existing `Insert`.
////
//// ### `columns(insert, columns) -> Insert(a)`
////
//// Set the column list. The number of columns **must** match the number of values
//// in each `InsertRow`.
////
//// ---
////
//// ## Conflict Strategies
////
//// ```mermaid
//// flowchart TD
////     A[Insert] --> B{on conflict}
////     B -->|error| C[InsertConflictError\ndefault - raise error]
////     B -->|ignore columns| D[on_columns_conflict_ignore\nPG + SQLite]
////     B -->|ignore constraint| E[on_constraint_conflict_ignore\nPG + SQLite]
////     B -->|upsert columns| F[on_columns_conflict_update\nPG + SQLite]
////     B -->|upsert constraint| G[on_constraint_conflict_update\nPG only]
////     B -->|duplicate key| H[on_duplicate_key_update\nMySQL + MariaDB]
//// ```
////
//// ### `on_conflict_error(insert) -> Insert(a)`
////
//// The default. Any uniqueness/constraint violation raises an error.
////
//// ### `on_columns_conflict_ignore(insert, columns, where) -> Insert(a)`
////
//// Silently skip conflicting rows when the conflict is on the given columns.
////
//// > Supported by 🐘 PostgreSQL and 🪶 SQLite.
////
//// ```gleam
//// i.from_values("users", ["email"], [i.row([i.string("a@b.com")])])
//// |> i.on_columns_conflict_ignore(
////   columns: ["email"],
////   where: w.none(),
//// )
//// // INSERT INTO users (email) VALUES ($1) ON CONFLICT (email) DO NOTHING
//// ```
////
//// ### `on_constraint_conflict_ignore(insert, constraint, where) -> Insert(a)`
////
//// Same as above but identifies the conflict target by constraint name.
////
//// > Supported by 🐘 PostgreSQL and 🪶 SQLite.
////
//// ### `on_columns_conflict_update(insert, columns, where, update) -> Insert(a)`
////
//// **Upsert** — insert or update on conflict (PostgreSQL / SQLite style).
////
//// Use `excluded.column` in your `Update` expressions to reference the values
//// that were being inserted.
////
//// > Supported by 🐘 PostgreSQL ✅ and 🪶 SQLite ✅.
//// > Not supported by 🦭 MariaDB or 🐬 MySQL — use `on_duplicate_key_update` instead.
////
//// ```gleam
//// import cake/update as u
////
//// i.from_values("scores", ["username", "score"], [
////   i.row([i.string("alice"), i.int(100)]),
//// ])
//// |> i.on_columns_conflict_update(
////   columns: ["username"],
////   where: w.none(),
////   update: u.new()
////     |> u.set(u.set_expression("score", "excluded.score")),
//// )
//// // INSERT INTO scores (username, score) VALUES ($1, $2)
//// // ON CONFLICT (username) DO UPDATE SET score = excluded.score
//// ```
////
//// ### `on_constraint_conflict_update(insert, constraint, where, update) -> Insert(a)`
////
//// Same as above but targets a named constraint.
////
//// > Supported by 🐘 PostgreSQL only.
////
//// ### `on_duplicate_key_update(insert, update) -> Insert(a)`
////
//// **MySQL / MariaDB upsert** using `ON DUPLICATE KEY UPDATE` syntax.
////
//// Use `VALUES(column)` (not `excluded.column`) in your `Update` expressions.
////
//// > Supported by 🦭 MariaDB ✅ and 🐬 MySQL ✅ only.
////
//// ```gleam
//// i.from_values("scores", ["username", "score"], [
////   i.row([i.string("alice"), i.int(100)]),
//// ])
//// |> i.on_duplicate_key_update(
////   update: u.new()
////     |> u.set(u.set_expression("score", "VALUES(score) + scores.score")),
//// )
//// // INSERT INTO scores (username, score) VALUES (?, ?)
//// // ON DUPLICATE KEY UPDATE score = VALUES(score) + scores.score
//// ```
////
//// ---
////
//// ## RETURNING
////
//// Fetch column values from the inserted rows (🐘 PostgreSQL and 🪶 SQLite).
////
//// > 🦭 MariaDB and 🐬 MySQL do not support `RETURNING` in `INSERT` queries.
////
//// ```gleam
//// i.from_values("users", ["name"], [i.row([i.string("Alice")])])
//// |> i.returning(["id", "name"])
//// // INSERT INTO users (name) VALUES ($1) RETURNING id, name
//// ```
////
//// | Function                  | Effect                    |
////
//// | Function             | Effect                    |
//// | ------             | ------                    |
//// | `returning(insert, cols)` | Return the listed columns |
//// | `no_returning(insert)`    | Remove RETURNING clause   |
////
//// ---
////
//// ## Modifier
////
//// A raw string modifier inserted after `INSERT` (e.g. `OR IGNORE` for SQLite).
////
//// ```gleam
//// i.new() |> i.modifier("OR IGNORE")
//// // INSERT OR IGNORE INTO ...
//// ```
////
//// ---
////
//// ## Epilog and Comment
////
//// ```gleam
//// i.new()
//// |> i.from_values("logs", ["msg"], [i.row([i.string("hello")])])
//// |> i.epilog("RETURNING id")
//// |> i.comment("audit log insert")
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/insert as i
//// import cake/update as u
//// import cake/where as w
////
//// type Product { Product(sku: String, price: Float) }
////
//// fn encode_product(p: Product) -> i.InsertRow {
////   i.row([i.string(p.sku), i.float(p.price)])
//// }
////
//// [Product("ABC-1", 9.99), Product("ABC-2", 14.99)]
//// |> i.from_records(
////   table_name: "products",
////   columns: ["sku", "price"],
////   encoder: encode_product,
//// )
//// |> i.on_columns_conflict_update(
////   columns: ["sku"],
////   where: w.none(),
////   update: u.new() |> u.set(u.set_expression("price", "excluded.price")),
//// )
//// |> i.returning(["id", "sku"])
//// |> i.to_query
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
import cake/internal/read_query.{Comment, Epilog, NoComment, NoEpilog}
import cake/internal/write_query.{
  Insert, InsertColumns, InsertConflictError, InsertConflictIgnore,
  InsertConflictTarget, InsertConflictTargetConstraint, InsertConflictUpdate,
  InsertDuplicateKeyUpdate, InsertFragment, InsertIntoTable, InsertModifier,
  InsertParam, InsertQuery, InsertRow, InsertSourceRecords, InsertSourceRows,
  NoInsertColumns, NoInsertIntoTable, NoInsertModifier, NoInsertSource,
  NoReturning, Returning,
}
import cake/param.{
  BoolParam, DateParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/string
import gleam/time/calendar

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Comment =
  read_query.Comment

pub type Epilog =
  read_query.Epilog

pub type Where =
  read_query.Where

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ write_query type re-exports                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Insert(a) =
  write_query.Insert(a)

pub type InsertColumns =
  write_query.InsertColumns

pub type InsertConflictStrategy(a) =
  write_query.InsertConflictStrategy(a)

pub type InsertIntoTable =
  write_query.InsertIntoTable

pub type InsertRow =
  write_query.InsertRow

pub type InsertSource(a) =
  write_query.InsertSource(a)

pub type InsertValue =
  write_query.InsertValue

pub type Update(a) =
  write_query.Update(a)

pub type WriteQuery(a) =
  write_query.WriteQuery(a)

/// Creates a `WriteQuery` from an `Insert` query.
///
pub fn to_query(insert insert: Insert(a)) -> WriteQuery(a) {
  insert |> InsertQuery
}

// ▒▒▒ Rows / Values / Params ▒▒▒

/// Create an `InsertRow` from a list of `InsertValue`s.
///
pub fn row(values values: List(InsertValue)) -> InsertRow {
  values |> InsertRow
}

/// Create an `InsertValue` from a column `String` and a `Bool` value.
///
pub fn bool(value value: Bool) -> InsertValue {
  value |> BoolParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `Float` value.
///
pub fn float(value value: Float) -> InsertValue {
  value |> FloatParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and an `Int` value.
///
pub fn int(value value: Int) -> InsertValue {
  value |> IntParam |> InsertParam
}

/// Create an `InsertValue` from a column `String` and a `String` value.
///
pub fn string(value value: String) -> InsertValue {
  value |> StringParam |> InsertParam
}

/// Create a NULL `InsertValue`.
///
pub fn null() -> InsertValue {
  NullParam |> InsertParam
}

/// Create an `InsertValue` from a `calendar.Date`.
///
pub fn date(date value: calendar.Date) -> InsertValue {
  value |> DateParam |> InsertParam
}

/// Create an `InsertValue` from a `Fragment`.
///
/// ## Example
///
/// ```gleam
/// import cake/fragment as f
/// import cake/insert as i
///
/// i.fragment(f.prepared("$::uuid", [f.string("0000000000-0000-4000-a000-a00000000000")]))
/// ```
///
pub fn fragment(value value: Fragment) -> InsertValue {
  InsertFragment(value)
}

// ▒▒▒ Constructors ▒▒▒

/// Create an empty `INSERT` query.
///
pub fn new() -> Insert(a) {
  Insert(
    table: NoInsertIntoTable,
    modifier: NoInsertModifier,
    source: NoInsertSource,
    columns: NoInsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Create an `INSERT` query from a list of gleam records.
///
/// The `encoder` function is used to convert each record into an `InsertRow`.
///
pub fn from_records(
  table_name table_name: String,
  columns columns: List(String),
  records records: List(a),
  encoder encoder: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(
    table: table_name |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: records |> InsertSourceRecords(encoder:),
    columns: columns |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Create an `INSERT` query from a list of `InsertRow`s.
///
pub fn from_values(
  table_name table_name: String,
  columns columns: List(String),
  values values: List(InsertRow),
) -> Insert(a) {
  Insert(
    table: table_name |> InsertIntoTable,
    modifier: NoInsertModifier,
    source: values |> InsertSourceRows,
    columns: columns |> InsertColumns,
    on_conflict: InsertConflictError,
    returning: NoReturning,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

// ▒▒▒ Table ▒▒▒

/// Specify the table to insert into.
///
pub fn table(
  insert insert: Insert(a),
  table_name table_name: String,
) -> Insert(a) {
  Insert(..insert, table: table_name |> InsertIntoTable)
}

/// Get the table name to insert into from an `Insert` query.
///
pub fn get_table(insert insert: Insert(a)) -> InsertIntoTable {
  insert.table
}

// ▒▒▒ Modifier ▒▒▒

/// Specify a modifier for the `INSERT` query.
///
pub fn modifier(
  insert insert: Insert(a),
  modifier modifier: String,
) -> Insert(a) {
  let modifier = modifier |> string.trim
  case modifier {
    "" -> Insert(..insert, modifier: NoInsertModifier)
    _ -> Insert(..insert, modifier: modifier |> InsertModifier)
  }
}

/// Specify that no modifier should be used for the given `INSERT` query.
///
pub fn no_modifier(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, modifier: NoInsertModifier)
}

/// Get the modifier from an `Insert` query.
///
pub fn get_modifier(insert insert: Insert(a)) -> String {
  case insert.modifier {
    NoInsertModifier -> ""
    InsertModifier(keyword:) -> keyword
  }
}

// ▒▒▒ Source ▒▒▒

/// Specify the source records to insert.
///
pub fn source_records(
  insert insert: Insert(a),
  source records: List(a),
  encoder encoder: fn(a) -> InsertRow,
) -> Insert(a) {
  Insert(..insert, source: records |> InsertSourceRecords(encoder:))
}

/// Specify the source values to insert.
///
pub fn source_values(
  insert insert: Insert(a),
  source rows: List(InsertRow),
) -> Insert(a) {
  Insert(..insert, source: rows |> InsertSourceRows)
}

/// Get the source from an `Insert` query which is either a list of records,
/// accompanied by an encoder function or a list of `InsertRow`s.
///
pub fn get_source(insert insert: Insert(a)) -> InsertSource(a) {
  insert.source
}

/// Specify the columns to insert into.
///
/// NOTICE: You have to specify the columns and ensure their names are
/// correct, as well as their count which must be equal to the count of
/// `InsertRows` the encoder function returns or is given as source
///          values.
///
pub fn columns(
  insert insert: Insert(a),
  columns columns: List(String),
) -> Insert(a) {
  Insert(..insert, columns: columns |> InsertColumns)
}

/// Get the columns to insert into from an `Insert` query.
///
pub fn get_columns(insert insert: Insert(a)) -> InsertColumns {
  insert.columns
}

// ▒▒▒ ON CONFLICT ▒▒▒

/// This specifies that any conflicts result in the query to fail
///
/// This is the default behaviour.
///
pub fn on_conflict_error(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, on_conflict: InsertConflictError)
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Columns
///
pub fn on_columns_conflict_ignore(
  insert insert: Insert(a),
  columns columns: List(String),
  where where: Where,
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictIgnore(
      target: columns |> InsertConflictTarget,
      where:,
    ),
  )
}

/// This specifies that specific conflicts do not result in an error but instead
/// are just ignored and not inserted.
///
/// Conflict Target: Constraint
///
pub fn on_constraint_conflict_ignore(
  insert insert: Insert(a),
  constraint constraint: String,
  where where: Where,
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictIgnore(
      target: constraint |> InsertConflictTargetConstraint,
      where:,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// This function generates PostgreSQL/SQLite-specific upsert queries using
/// `ON CONFLICT ... DO UPDATE` syntax.
///
/// **For MySQL/MariaDB, use `on_duplicate_key_update()` instead.**
///
/// Conflict Target: Columns
///
/// ## Important
///
/// - Use `excluded.column` in UPDATE expressions to reference insert values
/// - Explicitly specify which columns to check for conflicts
/// - Supports optional WHERE clause for conditional updates
///
/// ## Database Support
///
/// - **🐘PostgreSQL**: ✅ Fully supported
/// - **🪶SQLite**: ✅ Fully supported
/// - **🦭MariaDB**: ❌ Not supported - use `on_duplicate_key_update()`
/// - **🐬MySQL**: ❌ Not supported - use `on_duplicate_key_update()`
///
pub fn on_columns_conflict_update(
  insert insert: Insert(a),
  columns columns: List(String),
  where where: Where,
  update update: Update(a),
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictUpdate(
      target: columns |> InsertConflictTarget,
      where:,
      update:,
    ),
  )
}

/// Inserts or updates on conflict, also called ´UPSERT´.
///
/// This function generates PostgreSQL-specific upsert queries using
/// `ON CONFLICT ON CONSTRAINT ... DO UPDATE` syntax.
///
/// **For MySQL/MariaDB, use `on_duplicate_key_update()` instead.**
/// **For SQLite, use `on_columns_conflict_update()` instead.**
///
/// Conflict Target: Named Constraint
///
/// ## Database Support
///
/// - **🐘PostgreSQL**: ✅ Fully supported
/// - **🪶SQLite**: ❌ Not supported - use `on_columns_conflict_update()`
/// - **🦭MariaDB**: ❌ Not supported - use `on_duplicate_key_update()`
/// - **🐬MySQL**: ❌ Not supported - use `on_duplicate_key_update()`
///
pub fn on_constraint_conflict_update(
  insert insert: Insert(a),
  constraint constraint: String,
  where where: Where,
  update update: Update(a),
) -> Insert(a) {
  Insert(
    ..insert,
    on_conflict: InsertConflictUpdate(
      target: constraint |> InsertConflictTargetConstraint,
      where:,
      update:,
    ),
  )
}

/// Get the conflict strategy from an `Insert` query.
///
pub fn get_on_conflict(insert insert: Insert(a)) -> InsertConflictStrategy(a) {
  insert.on_conflict
}

// ▒▒▒ ON DUPLICATE KEY UPDATE (MySQL/MariaDB) ▒▒▒

/// MySQL/MariaDB upsert using `ON DUPLICATE KEY UPDATE` syntax.
///
/// This function generates MySQL/MariaDB-specific upsert queries.
/// **Only use this when targeting MySQL or MariaDB databases.**
///
/// For PostgreSQL/SQLite, use `on_columns_conflict_update()` or
/// `on_constraint_conflict_update()` instead.
///
/// ## Important
///
/// - Use `VALUES(column)` (not `excluded.column`) in your UPDATE expressions
/// - Updates occur on the **first** matched unique/primary key constraint
/// - No explicit conflict target - relies on existing indexes
///
/// ## Example
///
/// ```gleam
/// import cake/insert as i
/// import cake/update as u
///
/// [[i.string("user1"), i.int(100)] |> i.row]
/// |> i.from_values(table_name: "scores", columns: ["username", "score"])
/// |> i.on_duplicate_key_update(
///   update: u.new()
///     |> u.set("score" |> u.set_expression("VALUES(score) + scores.score")),
/// )
/// ```
///
/// Generates:
/// ```sql
/// INSERT INTO scores (username, score) VALUES (?, ?)
/// ON DUPLICATE KEY UPDATE score = VALUES(score) + scores.score
/// ```
///
/// ## Database Support
///
/// - **🦭MariaDB**: ✅ Supported
/// - **🐬MySQL**: ✅ Supported
/// - **🐘PostgreSQL**: ❌ Not supported - use `on_columns_conflict_update()`
/// - **🪶SQLite**: ❌ Not supported - use `on_columns_conflict_update()`
///
pub fn on_duplicate_key_update(
  insert insert: Insert(a),
  update update: Update(a),
) -> Insert(a) {
  Insert(..insert, on_conflict: InsertDuplicateKeyUpdate(update:))
}

// ▒▒▒ RETURNING ▒▒▒

/// Specify the columns to return after the `INSERT` query.
///
pub fn returning(
  insert insert: Insert(a),
  returning returning: List(String),
) -> Insert(a) {
  case returning {
    [] -> Insert(..insert, returning: NoReturning)
    _ -> Insert(..insert, returning: returning |> Returning)
  }
}

/// Specify that no columns should be returned after the `INSERT` query.
///
pub fn no_returning(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, returning: NoReturning)
}

// ▒▒▒ Epilog ▒▒▒

/// Specify an epilog for the `INSERT` query.
///
pub fn epilog(insert insert: Insert(a), epilog epilog: String) -> Insert(a) {
  let epilog = epilog |> string.trim
  case epilog {
    "" -> Insert(..insert, epilog: NoEpilog)
    _ -> Insert(..insert, epilog: { " " <> epilog } |> Epilog)
  }
}

/// Specify that no epilog should be added to the `INSERT` query.
///
pub fn no_epilog(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, epilog: NoEpilog)
}

/// Get the epilog from an `INSERT` query.
///
pub fn get_epilog(insert insert: Insert(a)) -> Epilog {
  insert.epilog
}

// ▒▒▒ Comment ▒▒▒

/// Specify a comment for the `INSERT` query.
///
pub fn comment(insert insert: Insert(a), comment comment: String) -> Insert(a) {
  let comment = comment |> string.trim
  case comment {
    "" -> Insert(..insert, comment: NoComment)
    _ -> Insert(..insert, comment: { " " <> comment } |> Comment)
  }
}

/// Specify that no comment should be added to the `INSERT` query.
///
pub fn no_comment(insert insert: Insert(a)) -> Insert(a) {
  Insert(..insert, comment: NoComment)
}

/// Get the comment from an `INSERT` query.
///
pub fn get_comment(insert insert: Insert(a)) -> Comment {
  insert.comment
}
