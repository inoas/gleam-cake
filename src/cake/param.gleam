//// A `Param` is a value that can be used in a query.
////
//// `Param` is the boxed value type used in prepared statements. Every piece of
//// user-supplied data that enters a query should be wrapped in a `Param` so the
//// driver can safely encode and transmit it separately from the SQL string.
////
//// ## Aliases
////
//// ```gleam
//// import cake/param as p
//// ```
////
//// ---
////
//// ## Concept
////
//// A `Param` carries a single typed value. It is never executed directly — it is
//// bound to a placeholder (`?`) at query time. This separation is what makes Cake
//// queries safe from SQL injection.
////
//// ```mermaid
//// flowchart LR
////     A[Gleam value] --> B[p.string, p.int, ...]
////     B --> C[Param]
////     C --> D[prepared statement]
////     D --> E[placeholder ?]
////     E --> F[driver encodes & binds]
////     F --> G[SQL + params sent to DB]
//// ```
////
//// ---
////
//// ## Param Constructors
////
//// Each constructor wraps a Gleam value into the corresponding `Param` variant.
////
//// | Function        | Gleam type      | SQL type           | Param variant      |
//// | ----------      | ----------      | ----------         | ----------         |
//// | `string(value)` | `String`        | `TEXT` / `VARCHAR` | `StringParam`      |
//// | `int(value)`    | `Int`           | Integer            | `IntParam`         |
//// | `float(value)`  | `Float`         | Float / Double     | `FloatParam`       |
//// | `bool(value)`   | `Bool`          | Boolean            | `BoolParam`        |
//// | `true()`        | —               | `TRUE`             | `BoolParam(True)`  |
//// | `false()`       | —               | `FALSE`            | `BoolParam(False)` |
//// | `null()`        | —               | `NULL`             | `NullParam`        |
//// | `date(value)`   | `calendar.Date` | `DATE`             | `DateParam`        |
////
//// ### `string(value: String) -> Param`
////
//// ```gleam
//// p.string("hello world")
//// ```
////
//// ### `int(value: Int) -> Param`
////
//// ```gleam
//// p.int(42)
//// ```
////
//// ### `float(value: Float) -> Param`
////
//// ```gleam
//// p.float(3.14)
//// ```
////
//// ### `bool(value: Bool) -> Param`
////
//// ```gleam
//// p.bool(True)
//// ```
////
//// ### `true() -> Param`
////
//// Convenience for `p.bool(True)`.
////
//// ### `false() -> Param`
////
//// Convenience for `p.bool(False)`.
////
//// ### `null() -> Param`
////
//// Represents an SQL `NULL`. Use when a column value is unknown or intentionally absent.
////
//// ```gleam
//// p.null()
//// ```
////
//// ### `date(value: calendar.Date) -> Param`
////
//// Wraps a Gleam `calendar.Date` into a `Param` suitable for `DATE` columns.
////
//// ```gleam
//// import gleam/time/calendar
////
//// p.date(calendar.from_iso_date("2025-01-15"))
//// ```
////
//// ---
////
//// ## Param Variants
////
//// The `Param` type has the following constructors:
////
//// | Constructor          | Description     |
////
//// | Constructor      | Description     |
//// | --------         | --------        |
//// | `StringParam(value)` | UTF-8 string    |
//// | `IntParam(value)`    | Integer         |
//// | `FloatParam(value)`  | Float           |
//// | `BoolParam(value)`   | Boolean         |
//// | `NullParam`          | SQL NULL        |
//// | `DateParam(value)`   | `calendar.Date` |
////
//// ---
////
//// ## Using Params in Queries
////
//// Params are typically created inside builder functions (e.g. `i.string()`,
//// `w.col()`) rather than imported directly, but you can use `cake/param`
//// convenience functions anywhere a `Param` is needed.
////
//// ### In WHERE conditions
////
//// ```gleam
//// import cake/select as s
//// import cake/where as w
////
//// s.new()
//// |> s.from_table("users")
//// |> s.col("name")
//// |> s.where(w.and([
////     w.eq(w.col("age"), w.int(p.int(18))),
////     w.eq(w.col("role"), w.string(p.string("admin"))),
//// ]))
//// |> s.to_query
//// ```
////
//// ### In INSERT values
////
//// ```gleam
//// import cake/insert as i
////
//// i.from_values("users", ["name", "age"], [
////   i.row([
////     i.string(p.string("Alice")),
////     i.int(p.int(30)),
////   ]),
//// ])
//// ```
////
//// ### In fragments
////
//// Params created via `cake/param` can be passed to `f.prepared()` in the same
//// way as the convenience constructors in `cake/fragment`.
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/insert as i
//// import cake/param as p
//// import cake/where as w
//// import gleam/time/calendar
////
//// type User {
////   User(name: String, age: Int, active: Bool, registered: calendar.Date)
//// }
////
//// let user = User("Alice", 30, True, calendar.from_iso_date("2025-01-15"))
////
//// i.from_values("users", ["name", "age", "active", "registered"], [
////   i.row([
////     i.string(p.string(user.name)),
////     i.int(p.int(user.age)),
////     i.bool(p.bool(user.active)),
////     i.date(p.date(user.registered)),
////   ]),
//// ])
//// |> i.to_query
//// // INSERT INTO users (name, age, active, registered) VALUES ($1, $2, $3, $4)
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

import gleam/time/calendar

// TODO v3 how to create DECIMAL, TIME and DATETIME

/// Params (e.g. parameters) are wrapped (boxed) literal values, that can be
/// used in SQL queries.
///
pub type Param {
  StringParam(value: String)
  IntParam(value: Int)
  FloatParam(value: Float)
  NullParam
  BoolParam(value: Bool)
  DateParam(value: calendar.Date)
  //
  // Not sure this should be here, but should it not?
  // Maybe add:
  // DecimalParam(Int, Int) TODO v2
  // JsonParam(String)
  // XmlParam(String)
  // UuidParam(String)
  // BinaryParam(any)
  // TimeParam(hour: Int, minute: Int, second: Int)
  // Time6Param(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)
  // DateTimeParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
  // DateTime6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int))
  // UnixTimeStampParam(Int)
  // TimeTzParam(hour: Int, minute: Int, second: Int, timezone: String)
  // Time6TzParam(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int), timezone: String)
  // DateTimeTzParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, timezone: String)
  // DateTimeTz6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int), timezone: String)
  // UnixTimeStampParam(Int)
  // BinaryParam(any)
  // UuidParam(String)
  // ArrayParam(Param)
  // ObjectParam(String, Param)
  // XmlParam(String)
  // CustomParam(encoder_fn: Function(custom), custom)
}

/// Create a new `Param` with a `Bool` value.
///
pub fn bool(value: Bool) -> Param {
  value |> BoolParam
}

/// Create a new `Param` with a `Float` value.
///
pub fn float(value: Float) -> Param {
  value |> FloatParam
}

/// Create a new `Param` with an `Int` value.
///
pub fn int(value: Int) -> Param {
  value |> IntParam
}

/// Create a new `Param` with a `String` value.
///
pub fn string(value: String) -> Param {
  value |> StringParam
}

/// Create a new `Param` with an SQL `NULL` value.
///
pub fn null() -> Param {
  NullParam
}

/// Create a new `Param` with a `calendar.Date` value.
///
pub fn date(value: calendar.Date) -> Param {
  value |> DateParam
}
//
// import cake/param
// import gleam/float
// import gleam/int
// import gleam/string
// import gleam/time/calendar

// pub fn debug(param: param.Param) -> String {
//   case param {
//     param.StringParam(value:) -> "'" <> value <> "'"
//     param.IntParam(value:) -> int.to_string(value)
//     param.FloatParam(value:) -> float.to_string(value)
//     param.BoolParam(True) -> "TRUE"
//     param.BoolParam(False) -> "FALSE"
//     param.NullParam -> "NULL"
//     param.DateParam(calendar.Date(year:, month:, day:)) -> {
//       let year =
//         year
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 4)
//       let month =
//         month
//         |> calendar.month_to_int
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 2)
//       let day =
//         day
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 2)
//       "SQL: " <> year <> "-" <> month <> "-" <> day
//     }
//   }
// }
