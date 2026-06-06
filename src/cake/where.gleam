//// Builds `WHERE` and `HAVING` conditions for `SELECT`, `UPDATE`, and `DELETE`
////
//// Where clauses are used to filter rows in a table.
////
//// Also used to build `HAVING` clauses for SQL queries, because they work the
//// same way as `WHERE` clauses, but are used to filter rows after `GROUP BY`
//// has been applied.
////
//// ## Aliases
////
//// ```gleam
//// import cake/where as w
//// ```
////
//// > The `Where` type is identical for both `WHERE` and `HAVING` contexts.
//// > Use the same `cake/where` functions in `s.having(...)` calls.
////
//// ---
////
//// ## Concept
////
//// A `Where` is a tree of conditions. Leaf nodes are comparisons; branch nodes
//// are logical combinators (`AND`, `OR`, `XOR`). You compose them freely and pass
//// the result to query builder functions like `s.where(...)`, `u.where(...)`, etc.
////
//// ```mermaid
//// flowchart TD
////     ROOT[AndWhere] --> A[eq: active = TRUE]
////     ROOT --> B[OrWhere]
////     B --> C[eq: role = admin]
////     B --> D[eq: role = mod]
//// ```
////
//// Corresponding code:
////
//// ```gleam
//// w.and([
////   w.eq(w.col("active"), w.bool(True)),
////   w.or([
////     w.eq(w.col("role"), w.string("admin")),
////     w.eq(w.col("role"), w.string("mod")),
////   ]),
//// ])
//// ```
////
//// ---
////
//// ## WhereValue constructors
////
//// A `WhereValue` is one operand in a comparison. It can be a column reference,
//// a literal parameter, a sub-query, or a fragment.
////
//// | Function                   | Produces                              |
//// | -------------------------- | ------------------------------------- |
//// | `col("table.column")`      | Column reference                      |
//// | `bool(value)`              | Boolean param                         |
//// | `true()`                   | `TRUE` param                          |
//// | `false()`                  | `FALSE` param                         |
//// | `float(value)`             | Float param                           |
//// | `int(value)`               | Integer param                         |
//// | `string(value)`            | String param                          |
//// | `null()`                   | `NULL` param                          |
//// | `date(value)`              | Date param                            |
//// | `sub_query(query)`         | Sub-query (must return single column) |
//// | `fragment_value(fragment)` | Raw SQL fragment                      |
////
//// ---
////
//// ## Logical combinators
////
//// ### `and(wheres) -> Where`
////
//// All conditions must be true (`AND`).
////
//// ```gleam
//// w.and([
////   w.eq(w.col("active"), w.bool(True)),
////   w.gt(w.col("age"), w.int(18)),
//// ])
//// // active = $1 AND age > $2
//// ```
////
//// ### `or(wheres) -> Where`
////
//// At least one condition must be true (`OR`).
////
//// ```gleam
//// w.or([
////   w.eq(w.col("status"), w.string("pending")),
////   w.eq(w.col("status"), w.string("processing")),
//// ])
//// // status = $1 OR status = $2
//// ```
////
//// ### `not(where) -> Where`
////
//// Negates a condition.
////
//// ```gleam
//// w.not(w.is_null(w.col("deleted_at")))
//// // NOT (deleted_at IS NULL)
//// ```
////
//// ### `xor(wheres) -> Where`
////
//// Exactly **one** condition must be true.
////
//// ```gleam
//// w.xor([w.eq(w.col("a"), w.int(1)), w.eq(w.col("b"), w.int(2))])
//// ```
////
//// | True conditions | Result |
//// | --------------- | ------ |
//// | 0               | FALSE  |
//// | 1               | TRUE   |
//// | 2+              | FALSE  |
////
//// ### `xor_parity(wheres) -> Where`
////
//// An **odd number** of conditions must be true (matches MySQL's native `XOR`).
////
//// ```gleam
//// w.xor_parity([cond_a, cond_b, cond_c])
//// ```
////
//// | True conditions | Result |
//// | --------------- | ------ |
//// | 0               | FALSE  |
//// | 1               | TRUE   |
//// | 2               | FALSE  |
//// | 3               | TRUE   |
////
//// > On 🦭 MariaDB / 🐬 MySQL: uses native `XOR`.
//// > On 🐘 PostgreSQL / 🪶 SQLite: emulated via integer arithmetic.
////
//// ### `none() -> Where`
////
//// An empty / no-op condition. Useful as a default when building conditions
//// conditionally.
////
//// ```gleam
//// let age_filter = case min_age {
////   Some(age) -> w.gte(w.col("age"), w.int(age))
////   None -> w.none()
//// }
//// ```
////
//// ---
////
//// ## Comparison operators
////
//// All comparisons take two `WhereValue`s.
////
//// | Function    | SQL      |
//// | ----------- | -------- |
//// | `eq(a, b)`  | `a = b`  |
//// | `neq(a, b)` | `a <> b` |
//// | `lt(a, b)`  | `a < b`  |
//// | `lte(a, b)` | `a <= b` |
//// | `gt(a, b)`  | `a > b`  |
//// | `gte(a, b)` | `a >= b` |
////
//// ```gleam
//// w.eq(w.col("status"), w.string("active"))
//// w.gt(w.col("score"), w.int(100))
//// w.lte(w.col("created_at"), w.date(cutoff))
//// ```
////
//// ---
////
//// ## NULL checks
////
//// ```gleam
//// w.is_null(w.col("deleted_at"))        // deleted_at IS NULL
//// w.is_not_null(w.col("email"))         // email IS NOT NULL
//// ```
////
//// ---
////
//// ## Boolean checks
////
//// ```gleam
//// w.is_true(w.col("active"))            // active IS TRUE
//// w.is_false(w.col("banned"))           // banned IS FALSE
//// w.is_bool(w.col("verified"), True)    // verified IS TRUE
//// w.is_not_bool(w.col("locked"), True)  // locked IS NOT TRUE
//// ```
////
//// ---
////
//// ## IN and BETWEEN
////
//// ### `in(value, values) -> Where`
////
//// ```gleam
//// w.in(w.col("status"), [w.string("active"), w.string("pending")])
//// // status IN ($1, $2)
//// ```
////
//// ### `in_query(value, sub_query) -> Where`
////
//// ```gleam
//// import cake/select as s
////
//// let active_ids =
////   s.new()
////   |> s.from_table("subscriptions")
////   |> s.col("user_id")
////   |> s.where(w.eq(w.col("active"), w.bool(True)))
////   |> s.to_query
////
//// w.in_query(w.col("users.id"), active_ids)
//// // users.id IN (SELECT user_id FROM subscriptions WHERE active = $1)
//// ```
////
//// ### `exists_in_query(sub_query) -> Where`
////
//// ```gleam
//// w.exists_in_query(active_ids)
//// // EXISTS (SELECT user_id FROM subscriptions WHERE active = $1)
//// ```
////
//// ### `between(a, b, c) -> Where`
////
//// ```gleam
//// w.between(w.col("age"), w.int(18), w.int(65))
//// // age BETWEEN $1 AND $2
//// ```
////
//// ---
////
//// ## Pattern matching
////
//// ### `like(value, pattern) -> Where`
////
//// Case-sensitive pattern match. Use `%` for any sequence and `_` for any single
//// character.
////
//// ```gleam
//// w.like(w.col("name"), "Alice%")
//// // name LIKE $1
//// ```
////
//// ### `ilike(value, pattern) -> Where`
////
//// Case-insensitive variant of `LIKE`.
////
//// ### `similar_to(value, pattern, escape_with) -> Where`
////
//// SQL regex pattern matching.
////
//// > Not supported by 🪶 SQLite.
////
//// ```gleam
//// w.similar_to(w.col("phone"), "([0-9]{3}-)?[0-9]{3}-[0-9]{4}", "\\")
//// ```
////
//// ---
////
//// ## Sub-query comparisons (ANY / ALL)
////
//// > Not supported by 🪶 SQLite.
////
//// ### ANY — true if **at least one** row in the sub-query satisfies the comparison
////
//// | Function              | SQL           |
//// | --------------------- | ------------- |
//// | `eq_any_query(v, q)`  | `v = ANY(q)`  |
//// | `neq_any_query(v, q)` | `v <> ANY(q)` |
//// | `lt_any_query(v, q)`  | `v < ANY(q)`  |
//// | `lte_any_query(v, q)` | `v <= ANY(q)` |
//// | `gt_any_query(v, q)`  | `v > ANY(q)`  |
//// | `gte_any_query(v, q)` | `v >= ANY(q)` |
////
//// ### ALL — true only if **every** row in the sub-query satisfies the comparison
////
//// | Function              | SQL           |
//// | --------------------- | ------------- |
//// | `eq_all_query(v, q)`  | `v = ALL(q)`  |
//// | `neq_all_query(v, q)` | `v <> ALL(q)` |
//// | `lt_all_query(v, q)`  | `v < ALL(q)`  |
//// | `lte_all_query(v, q)` | `v <= ALL(q)` |
//// | `gt_all_query(v, q)`  | `v > ALL(q)`  |
//// | `gte_all_query(v, q)` | `v >= ALL(q)` |
////
//// ```gleam
//// w.gt_all_query(w.col("salary"), avg_salary_query)
//// // salary > ALL(SELECT AVG(salary) FROM ...)
//// ```
////
//// ---
////
//// ## Raw fragment condition
////
//// ```gleam
//// import cake/fragment as f
////
//// w.fragment(f.prepared("? @> ?::jsonb", [
////   f.string("tags"),
////   f.string("[\"gleam\"]"),
//// ]))
//// ```
////
//// ---
////
//// ## Full Example
////
//// ```gleam
//// import cake/select as s
//// import cake/where as w
////
//// let query =
////   s.new()
////   |> s.from_table("users")
////   |> s.select_cols(["id", "name", "email"])
////   |> s.where(w.and([
////     w.is_not_null(w.col("email")),
////     w.or([
////       w.eq(w.col("role"), w.string("admin")),
////       w.and([
////         w.eq(w.col("role"), w.string("user")),
////         w.is_true(w.col("active")),
////       ]),
////     ]),
////     w.gte(w.col("created_at"), w.date(start_date)),
////   ]))
////   |> s.order_by_asc("name")
////   |> s.to_query
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
  AndWhere, Equal, Greater, GreaterOrEqual, Lower, LowerOrEqual, NoWhere,
  NotWhere, OrWhere, Unequal, WhereAllOfSubQuery, WhereAnyOfSubQuery,
  WhereBetween, WhereColumnValue, WhereComparison, WhereExistsInSubQuery,
  WhereFragment, WhereFragmentValue, WhereILike, WhereIn, WhereIsBool,
  WhereIsNotBool, WhereIsNotNull, WhereIsNull, WhereLike, WhereParamValue,
  WhereSimilarTo, WhereSubQueryValue, XorParityWhere, XorWhere,
}
import cake/param.{
  BoolParam, DateParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/time/calendar

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ read_query type re-exports                                                │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Fragment =
  read_query.Fragment

pub type ReadQuery =
  read_query.ReadQuery

pub type Where =
  read_query.Where

pub type WhereValue =
  read_query.WhereValue

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Where Value constructors                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

/// Creates a `WhereValue` from a column name `String`.
///
pub fn col(name name: String) -> WhereValue {
  WhereColumnValue(name:)
}

/// Creates a `WhereValue` from a `Float`.
///
pub fn float(value value: Float) -> WhereValue {
  FloatParam(value) |> WhereParamValue
}

/// Creates a `WhereValue` from an `Int`.
///
pub fn int(value value: Int) -> WhereValue {
  IntParam(value) |> WhereParamValue
}

/// Creates a `WhereValue` from a `String`.
///
pub fn string(value value: String) -> WhereValue {
  StringParam(value) |> WhereParamValue
}

/// Creates a `NULL` `WhereValue`.
///
pub fn null() -> WhereValue {
  NullParam |> WhereParamValue
}

/// Creates a `WhereValue` from a `calendar.Date`.
///
pub fn date(value value: calendar.Date) -> WhereValue {
  DateParam(value) |> WhereParamValue
}

/// Creates a `TRUE` `WhereValue`.
///
/// Notice: You probably want to use `where.is_true()` instead.
///
pub fn true() -> WhereValue {
  True |> BoolParam |> WhereParamValue
}

/// Creates a `FALSE` `WhereValue`.
///
/// Notice: You probably want to use `where.is_false()` instead.
///
pub fn false() -> WhereValue {
  False |> BoolParam |> WhereParamValue
}

/// Creates a `WhereValue` from a `Bool`.
///
pub fn bool(value value: Bool) -> WhereValue {
  BoolParam(value) |> WhereParamValue
}

/// Creates a `WhereValue` off a `ReadQuery`.
///
/// NOTICE: Usually the sub-query must return a single column.
///
pub fn sub_query(query query: ReadQuery) -> WhereValue {
  WhereSubQueryValue(query:)
}

/// Creates a `WhereValue` from a `Fragment`.
///
pub fn fragment_value(fragment fragment: Fragment) -> WhereValue {
  WhereFragmentValue(value: fragment)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Where constructors                                                        │
// └───────────────────────────────────────────────────────────────────────────┘

/// Negates a `Where`.
///
pub fn not(where where: Where) -> Where {
  NotWhere(condition: where)
}

/// Logical AND of multiple `Where`s.
///
pub fn and(wheres wheres: List(Where)) -> Where {
  AndWhere(conditions: wheres)
}

/// Logical OR of multiple `Where`s.
///
pub fn or(wheres wheres: List(Where)) -> Where {
  OrWhere(conditions: wheres)
}

/// Logical XOR of multiple `Where`s.
///
/// Returns `TRUE` when **exactly one** condition is true.
///
/// Unlike `xor_parity`, which returns `TRUE` for any **odd number** of true
/// conditions, `xor` is stricter: two or more true conditions yield `FALSE`.
///
/// | Number of conditions true | Result |
/// |---------------------------|--------|
/// |                         0 | FALSE  |
/// |                         1 | TRUE   |
/// |                         2 | FALSE  |
/// |                         3 | FALSE  |
/// |                         4 | FALSE  |
///
pub fn xor(wheres wheres: List(Where)) -> Where {
  XorWhere(conditions: wheres)
}

/// Logical XOR of multiple `Where`s using left-associative binary XOR.
///
/// Unlike `xor`, which returns `TRUE` when _exactly one_ condition is true,
/// `xor_parity` returns `TRUE` when an **odd number** of conditions are true —
/// matching the behaviour of MySQL's and MariaDB's native `XOR` operator.
///
/// | Number of conditions true | Result |
/// |---------------------------|--------|
/// |                         0 | FALSE  |
/// |                         1 | TRUE   |
/// |                         2 | FALSE  |
/// |                         3 | TRUE   |
/// |                         4 | FALSE  |
///
/// **NULL handling:** if any predicate evaluates to `NULL`, the entire
/// expression evaluates to `NULL`, which a `WHERE` clause treats as no
/// match (NULL-poisoning). This is consistent across all adapters:
///
/// - 🐘PostgreSQL / 🪶SQLite emulate parity via integer arithmetic;
///   a NULL predicate propagates as NULL through the sum and modulo.
/// - 🦭MariaDB / 🐬MySQL use native `XOR`, where `NULL XOR anything = NULL`.
///
/// For adapters 🦭MariaDB or 🐬MySQL the native `XOR` syntax will be
/// utilized under the hood.
///
pub fn xor_parity(wheres wheres: List(Where)) -> Where {
  XorParityWhere(conditions: wheres)
}

/// No where condition.
///
pub fn none() -> Where {
  NoWhere
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a `Bool`.
pub fn is_bool(value value: WhereValue, bool bool: Bool) -> Where {
  value |> WhereIsBool(expected: bool)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` does not match a
/// `Bool`.
pub fn is_not_bool(value value: WhereValue, bool bool: Bool) -> Where {
  value |> WhereIsNotBool(expected: bool)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `False`.
pub fn is_false(value value: WhereValue) -> Where {
  value |> WhereIsBool(expected: False)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `True`.
pub fn is_true(value value: WhereValue) -> Where {
  value |> WhereIsBool(expected: True)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is SQL `NULL`.
///
pub fn is_null(value value: WhereValue) -> Where {
  WhereIsNull(value:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not SQL `NULL`.
///
pub fn is_not_null(value value: WhereValue) -> Where {
  WhereIsNotNull(value:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` equals another
/// `WhereValue`.
///
pub fn eq(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: Equal, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower than another
/// `WhereValue`.
///
pub fn lt(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: Lower, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower or equal to
/// another `WhereValue`.
///
pub fn lte(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: LowerOrEqual, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than
/// another `WhereValue`.
///
pub fn gt(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: Greater, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to another `WhereValue`.
///
pub fn gte(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: GreaterOrEqual, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not equal to
/// another `WhereValue`.
///
pub fn neq(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  WhereComparison(value_a:, operator: Unequal, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches any
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn eq_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: Equal, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower than an any
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn lt_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: Lower, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower or equal to
/// any in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn lte_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: LowerOrEqual, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than any
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn gt_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: Greater, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to any in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn gte_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: GreaterOrEqual, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not equal to any
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn neq_any_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAnyOfSubQuery(value_a: value, operator: Unequal, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches all
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn eq_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: Equal, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower than all
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn lt_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: Lower, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower or equal to
/// all in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn lte_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: LowerOrEqual, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than all
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn gt_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: Greater, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to all in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn gte_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: GreaterOrEqual, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not equal to all
/// in a sub-query.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn neq_all_query(
  value value: WhereValue,
  sub_query query: ReadQuery,
) -> Where {
  WhereAllOfSubQuery(value_a: value, operator: Unequal, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is IN a sub-query.
///
/// NOTICE: Usually the sub-query must return a single column.
///
pub fn in_query(value value: WhereValue, sub_query query: ReadQuery) -> Where {
  WhereIn(value:, values: [WhereSubQueryValue(query:)])
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is in a list of
/// `WhereValue`s.
///
pub fn in(value value: WhereValue, values values: List(WhereValue)) -> Where {
  WhereIn(value:, values:)
}

/// Creates a `WHERE` clause that checks if it exists in a sub-query.
///
pub fn exists_in_query(sub_query query: ReadQuery) -> Where {
  WhereExistsInSubQuery(query:)
}

// TODO v2 consider adding this
// pub fn wrap_in_parentheses(where: Where) -> Where {
//   where |> WhereParentheses
// }

/// Creates a `WHERE` clause that checks if a `WhereValue` A is between two
/// `WhereValue`s B and C.
///
pub fn between(
  value_a value_a: WhereValue,
  value_b value_b: WhereValue,
  value_c value_c: WhereValue,
) -> Where {
  WhereBetween(value_a:, value_b:, value_c:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
/// The pattern can contain for example the following wildcards:
///
/// - `%` matches any sequence of characters.
/// - `_` matches any single character.
///
pub fn like(value value: WhereValue, pattern pattern: String) -> Where {
  WhereLike(value:, pattern:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
///
/// `ilike` is the same as `like` but case-insensitive.
///
pub fn ilike(value value: WhereValue, pattern pattern: String) -> Where {
  WhereILike(value:, pattern:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is similar to a
/// pattern.
///
/// NOTICE: Not supported by 🪶SQLite.
///
pub fn similar_to(
  value value: WhereValue,
  to pattern: String,
  escape_with escape_char: String,
) -> Where {
  WhereSimilarTo(value:, pattern:, escape_char:)
}

/// Creates a `WhereFragment` from a `Fragment`.
///
pub fn fragment(fragment fragment: Fragment) -> Where {
  WhereFragment(value: fragment)
}
