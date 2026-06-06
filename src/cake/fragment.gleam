//// Fragments are low level building blocks of queries which allow direct
//// manipulation of the query string.
////
//// If you want to insert parameters, you are required to use prepared
//// fragments, which will be validated against the number of parameters given
//// and the parameters are automatically escaped by the RDBMS to prevent SQL
//// injections.
////
//// Low-level building blocks for injecting raw SQL into queries while keeping
//// parameter binding safe.
////
//// ## Aliases
////
//// ```gleam
//// import cake/fragment as f
//// ```
////
//// ---
////
//// ## When to use fragments
////
//// Use fragments when Cake's typed builder functions do not cover your use case:
////
//// - Database-specific functions (`NOW()`, `ARRAY_AGG(...)`, `JSON_BUILD_OBJECT(...)`)
//// - Type casts (`$1::uuid`, `? AS UNSIGNED`)
//// - Any SQL expression not expressible through the standard API
////
//// > ⛔ **Never** pass uncontrolled user input through `f.literal()`.
//// > Always use `f.prepared()` with typed params to bind user data safely.
////
//// ---
////
//// ## Fragment constructors
////
//// ### `prepared(string, params) -> Fragment`
////
//// Creates a fragment where `?` placeholders (the value of `f.placeholder`) are
//// replaced with safely-bound parameters at query execution time.
////
//// ```gleam
//// f.prepared("?::uuid", [f.string("0000-0000-4000-a000-a00000000000")])
//// ```
////
//// The placeholder character is exported as the constant `f.placeholder` (the `?`
//// grapheme). Use it when constructing fragment strings dynamically.
////
//// > ⛔ If the number of placeholders does not match the number of params, an
//// > error is printed to stderr and the fragment is created with best-effort
//// > fallback behaviour:
//// >
//// > - Too many placeholders → last param is repeated.
//// > - Too many params → excess params are ignored.
////
//// ### `literal(string) -> Fragment`
////
//// Creates a fragment from a **static, developer-controlled** SQL string.
//// No parameter substitution occurs.
////
//// ```gleam
//// f.literal("NOW()")
//// f.literal("CURRENT_TIMESTAMP")
//// f.literal("COUNT(*)")
//// ```
////
//// > ⛔ **YOU ARE FORBIDDEN TO INSERT UNCONTROLLED USER INPUT THIS WAY.**
////
//// ---
////
//// ## Placeholder
////
//// ```gleam
//// f.placeholder  // the "?" grapheme used inside prepared fragment strings
//// ```
////
//// ---
////
//// ## Param constructors
////
//// Params are the typed values passed to `f.prepared()`. They are escaped by the
//// database driver, preventing SQL injection.
////
//// | Function       | Gleam type      | SQL type      |
//// | ----------     | ----------      | ------------- |
//// | `bool(value)`   | `Bool`          | Boolean       |
//// | `true()`        | —               | `TRUE`        |
//// | `false()`       | —               | `FALSE`       |
//// | `float(value)`  | `Float`         | Float         |
//// | `int(value)`    | `Int`           | Integer       |
//// | `string(value)` | `String`        | String / Text |
//// | `null()`        | —               | `NULL`        |
//// | `date(value)`   | `calendar.Date` | Date          |
////
//// ---
////
//// ## Using fragments in queries
////
//// Fragments can appear in several positions depending on context:
////
//// ```mermaid
//// flowchart TD
////     A[Fragment] --> B[SelectValue\ns.fragment]
////     A --> C[InsertValue\ni.fragment]
////     A --> D[UpdateSet\nu.set_fragment]
////     A --> E[WhereValue\nw.fragment_value]
////     A --> F[Where condition\nw.fragment]
//// ```
////
//// ### In SELECT projections
////
//// ```gleam
//// import cake/select as s
//// import cake/fragment as f
////
//// s.new()
//// |> s.from_table("orders")
//// |> s.select(s.fragment(f.literal("SUM(amount)")) |> s.alias("total"))
//// ```
////
//// ### In INSERT values
////
//// ```gleam
//// import cake/insert as i
//// import cake/fragment as f
////
//// i.from_values("users", ["id", "name"], [
////   i.row([
////     i.fragment(f.prepared("?::uuid", [f.string("abc-123")])),
////     i.string("Alice"),
////   ]),
//// ])
//// ```
////
//// ### In UPDATE SET
////
//// ```gleam
//// import cake/update as u
//// import cake/fragment as f
////
//// u.new()
//// |> u.table("sessions")
//// |> u.set(u.set_fragment("expires_at", f.literal("NOW() + INTERVAL '1 hour'")))
//// ```
////
//// ### In WHERE — as a value operand
////
//// ```gleam
//// import cake/where as w
//// import cake/fragment as f
////
//// w.eq(
////   w.col("tags"),
////   w.fragment_value(f.prepared("?::jsonb", [f.string("[\"gleam\"]")])),
//// )
//// ```
////
//// ### In WHERE — as a full condition
////
//// ```gleam
//// w.fragment(f.prepared("? @> ?::jsonb", [
////   f.string("tags"),
////   f.string("[\"gleam\"]"),
//// ]))
//// ```
////
//// ---
////
//// ## Safety reference
////
//// |                | `f.prepared` | `f.literal` |
//// | ------         | ----------   | ----------- |
//// | User input safe    | ✅           | ❌          |
//// | Param substitution | ✅           | ❌          |
//// | Static SQL only    | ❌           | ✅          |
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/select as s
//// import cake/where as w
//// import cake/fragment as f
////
//// // Select users whose tags JSON array contains "gleam"
//// s.new()
//// |> s.from_table("users")
//// |> s.select_cols(["id", "name"])
//// |> s.select(s.fragment(f.literal("tags::text")) |> s.alias("tags_text"))
//// |> s.where(w.fragment(
////   f.prepared("tags @> ?::jsonb", [f.string("[\"gleam\"]")]),
//// ))
//// |> s.order_by_asc("name")
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

import cake/internal/read_query
import cake/param.{
  type Param, BoolParam, DateParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/time/calendar

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Fragment =
  read_query.Fragment

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ fragment                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

/// This placeholder must be used when building fragments with parameters.
///
pub const placeholder = read_query.fragment_placeholder_grapheme

/// Create a new fragment from a string and a list of parameters.
///
/// ⛔ ⛔ ⛔
///
/// If you mismatch the number of placeholders with the number of
/// parameters, an error will be printed to stderr and the fragment will be
/// created with the given parameters:
///
/// - If there are too many placeholders, the fragment will be created with the
///   given parameters and the last parameter will be repeated for the remaining
///   placeholders.
/// - If there are too many parameters, the fragment will be created with the
///   given parameters and the excess parameters will be ignored.
///
/// ⛔ ⛔ ⛔
///
pub fn prepared(string: String, params: List(Param)) -> Fragment {
  let placeholder_count =
    string
    |> read_query.fragment_prepared_split_string
    |> read_query.fragment_count_placeholders

  let param_count = params |> list.length

  case
    placeholder_count,
    param_count,
    placeholder_count |> int.compare(with: param_count)
  {
    0, 0, order.Eq -> {
      string |> read_query.FragmentLiteral
    }
    _n, _n, order.Eq -> {
      string |> read_query.FragmentPrepared(params)
    }
    0, _n, _not_eq -> {
      io.println_error(
        "Fragment had 0 "
        <> placeholder
        <> "-placeholders, but "
        <> param_count |> int.to_string
        <> " params given!",
      )
      string |> read_query.FragmentLiteral
    }
    _n, 0, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> placeholder_count |> int.to_string
        <> " "
        <> placeholder
        <> "-placeholders, but 0 params given!",
      )
      string |> read_query.FragmentLiteral
    }
    _n, _m, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> placeholder_count |> int.to_string
        <> " "
        <> placeholder
        <> "-placeholders, but "
        <> param_count |> int.to_string
        <> " params given!",
      )
      string |> read_query.FragmentPrepared(params)
    }
  }
}

/// Create a new fragment from a literal string.
///
/// ⛔ ⛔ ⛔
///
/// WARNING: YOU ARE FORBIDDEN TO INSERT UNCONTROLLED USER INPUT THIS WAY!
///
/// ⛔ ⛔ ⛔
///
pub fn literal(string: String) -> Fragment {
  string |> read_query.FragmentLiteral
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ params                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Create a new `Param` with a `Bool` value.
///
pub fn bool(value: Bool) -> Param {
  value |> BoolParam
}

/// Create a new `Param` with a `True` value.
///
pub fn true() -> Param {
  True |> BoolParam
}

/// Create a new `Param` with a `False` value.
///
pub fn false() -> Param {
  False |> BoolParam
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
