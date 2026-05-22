//// Used to build `WHERE` clauses for SQL queries.
////
//// Where clauses are used to filter rows in a table.
////
//// Also used to build `HAVING` clauses for SQL queries, because they work the
//// same way as `WHERE` clauses, but are used to filter rows after `GROUP BY`
//// has been applied.
////
//// ## Compatibility
////
//// - 🪶SQLite does not support `ANY`, `ALL` and `SIMILAR TO`.
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
  name |> WhereColumnValue
}

/// Creates a `WhereValue` from a `Float`.
///
pub fn float(v value: Float) -> WhereValue {
  value |> FloatParam |> WhereParamValue
}

/// Creates a `WhereValue` from an `Int`.
///
pub fn int(v value: Int) -> WhereValue {
  value |> IntParam |> WhereParamValue
}

/// Creates a `WhereValue` from a `String`.
///
pub fn string(v value: String) -> WhereValue {
  value |> StringParam |> WhereParamValue
}

/// Creates a `NULL` `WhereValue`.
///
pub fn null() -> WhereValue {
  NullParam |> WhereParamValue
}

/// Creates a `WhereValue` from a `calendar.Date`.
///
pub fn date(v value: calendar.Date) -> WhereValue {
  value |> DateParam |> WhereParamValue
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
  value |> BoolParam |> WhereParamValue
}

/// Creates a `WhereValue` off a `ReadQuery`.
///
/// NOTICE: Usually the sub-query must return a single column.
///
pub fn sub_query(query query: ReadQuery) -> WhereValue {
  query |> WhereSubQueryValue
}

/// Creates a `WhereValue` from a `Fragment`.
///
pub fn fragment_value(fragment fragment: Fragment) -> WhereValue {
  fragment |> WhereFragmentValue
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Where constructors                                                        │
// └───────────────────────────────────────────────────────────────────────────┘

/// Negates a `Where`.
///
pub fn not(where where: Where) -> Where {
  where |> NotWhere
}

/// Logical AND of multiple `Where`s.
///
pub fn and(wheres wheres: List(Where)) -> Where {
  wheres |> AndWhere
}

/// Logical OR of multiple `Where`s.
///
pub fn or(wheres wheres: List(Where)) -> Where {
  wheres |> OrWhere
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
  wheres |> XorWhere
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
  wheres |> XorParityWhere
}

/// No where condition.
///
pub fn none() -> Where {
  NoWhere
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a `Bool`.
pub fn is_bool(value value: WhereValue, bool bool: Bool) -> Where {
  value |> WhereIsBool(bool:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` does not match a
/// `Bool`.
pub fn is_not_bool(value value: WhereValue, bool bool: Bool) -> Where {
  value |> WhereIsNotBool(bool:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `False`.
pub fn is_false(value value: WhereValue) -> Where {
  value |> WhereIsBool(bool: False)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `True`.
pub fn is_true(value value: WhereValue) -> Where {
  value |> WhereIsBool(bool: True)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is SQL `NULL`.
///
pub fn is_null(value value: WhereValue) -> Where {
  value |> WhereIsNull
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not SQL `NULL`.
///
pub fn is_not_null(value value: WhereValue) -> Where {
  value |> WhereIsNotNull
}

/// Creates a `WHERE` clause that checks if a `WhereValue` equals another
/// `WhereValue`.
///
pub fn eq(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: Equal, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower than another
/// `WhereValue`.
///
pub fn lt(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: Lower, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower or equal to
/// another `WhereValue`.
///
pub fn lte(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: LowerOrEqual, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than
/// another `WhereValue`.
///
pub fn gt(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: Greater, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to another `WhereValue`.
///
pub fn gte(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: GreaterOrEqual, value_b:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not equal to
/// another `WhereValue`.
///
pub fn neq(value_a value_a: WhereValue, value_b value_b: WhereValue) -> Where {
  value_a |> WhereComparison(operator: Unequal, value_b:)
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
  value |> WhereAnyOfSubQuery(operator: Equal, query:)
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
  value |> WhereAnyOfSubQuery(operator: Lower, query:)
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
  value |> WhereAnyOfSubQuery(operator: LowerOrEqual, query:)
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
  value |> WhereAnyOfSubQuery(operator: Greater, query:)
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
  value |> WhereAnyOfSubQuery(operator: GreaterOrEqual, query:)
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
  value |> WhereAnyOfSubQuery(operator: Unequal, query:)
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
  value |> WhereAllOfSubQuery(operator: Equal, query:)
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
  value |> WhereAllOfSubQuery(operator: Lower, query:)
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
  value |> WhereAllOfSubQuery(operator: LowerOrEqual, query:)
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
  value |> WhereAllOfSubQuery(operator: Greater, query:)
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
  value |> WhereAllOfSubQuery(operator: GreaterOrEqual, query:)
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
  value |> WhereAllOfSubQuery(operator: Unequal, query:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is IN a sub-query.
///
/// NOTICE: Usually the sub-query must return a single column.
///
pub fn in_query(value value: WhereValue, sub_query query: ReadQuery) -> Where {
  value |> WhereIn(values: [query |> WhereSubQueryValue])
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is in a list of
/// `WhereValue`s.
///
pub fn in(value value: WhereValue, values values: List(WhereValue)) -> Where {
  value |> WhereIn(values:)
}

/// Creates a `WHERE` clause that checks if it exists in a sub-query.
///
pub fn exists_in_query(sub_query query: ReadQuery) -> Where {
  query |> WhereExistsInSubQuery
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
  value_a |> WhereBetween(value_b:, value_c:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
/// The pattern can contain for example the following wildcards:
///
/// - `%` matches any sequence of characters.
/// - `_` matches any single character.
///
pub fn like(value value: WhereValue, pattern pattern: String) -> Where {
  value |> WhereLike(pattern:)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
///
/// `ilike` is the same as `like` but case-insensitive.
///
pub fn ilike(value value: WhereValue, pattern pattern: String) -> Where {
  value |> WhereILike(pattern:)
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
  value |> WhereSimilarTo(pattern:, escape_char:)
}

/// Creates a `WhereFragment` from a `Fragment`.
///
pub fn fragment(fragment fragment: Fragment) -> Where {
  fragment |> WhereFragment
}
