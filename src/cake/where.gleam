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
//// - SQLite does not support `ANY`, `ALL` and `SIMILAR TO`.
////

import cake/internal/param
import cake/internal/query.{
  type Fragment, type Query, type Where, type WhereValue, AndWhere, Equal,
  Greater, GreaterOrEqual, Lower, LowerOrEqual, NotWhere, OrWhere,
  WhereAllOfSubQuery, WhereAnyOfSubQuery, WhereBetween, WhereColumnValue,
  WhereComparison, WhereExistsInSubQuery, WhereFragment, WhereFragmentValue,
  WhereILike, WhereIn, WhereIsBool, WhereIsNotBool, WhereIsNotNull, WhereIsNull,
  WhereLike, WhereParamValue, WhereSimilarTo, XorWhere,
}

/// Creates a `WhereValue` from a column name `String`.
///
pub fn col(name: String) -> WhereValue {
  name |> WhereColumnValue
}

/// Creates a `WhereValue` from a `Float`.
///
pub fn float(v vl: Float) -> WhereValue {
  vl |> param.float |> WhereParamValue
}

/// Creates a `WhereValue` from an `Int`.
///
pub fn int(v vl: Int) -> WhereValue {
  vl |> param.int |> WhereParamValue
}

/// Creates a `WhereValue` from a `String`.
///
pub fn string(v vl: String) -> WhereValue {
  vl |> param.string |> WhereParamValue
}

/// Creates a `NULL` `WhereValue`.
///
pub fn null() -> WhereValue {
  param.NullParam |> WhereParamValue
}

/// Negates a `Where`.
///
pub fn not(where whr: Where) -> Where {
  whr |> NotWhere
}

/// Logical AND of multiple `Where`s.
///
pub fn and(wheres whrs: List(Where)) -> Where {
  whrs |> AndWhere
}

/// Logical OR of multiple `Where`s.
///
pub fn or(wheres whrs: List(Where)) -> Where {
  whrs |> OrWhere
}

/// Logical XOR of multiple `Where`s.
///
pub fn xor(wheres whrs: List(Where)) -> Where {
  whrs |> XorWhere
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a `Bool`.
pub fn is_bool(value vl: WhereValue, bool b: Bool) -> Where {
  vl |> WhereIsBool(b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` does not match a `Bool`.
pub fn is_not_bool(value vl: WhereValue, bool b: Bool) -> Where {
  vl |> WhereIsNotBool(b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `False`.
pub fn is_false(value vl: WhereValue) -> Where {
  vl |> WhereIsBool(False)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is `True`.
pub fn is_true(value vl: WhereValue) -> Where {
  vl |> WhereIsBool(True)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is SQL `NULL`.
///
pub fn is_null(value vl: WhereValue) -> Where {
  vl |> WhereIsNull
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is not SQL `NULL`.
///
pub fn is_not_null(value vl: WhereValue) -> Where {
  vl |> WhereIsNotNull
}

/// Creates a `WHERE` clause that checks if a `WhereValue` equals another
/// `WhereValue`.
///
pub fn eq(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Equal, vl_b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower than another
/// `WhereValue`.
///
pub fn lt(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Lower, vl_b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` lower or equal to
/// another `WhereValue`.
///
pub fn lte(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(LowerOrEqual, vl_b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than
/// another `WhereValue`.
///
pub fn gt(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Greater, vl_b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to another `WhereValue`.
///
pub fn gte(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(GreaterOrEqual, vl_b)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches any
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn eq_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Equal, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower than an any
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn lt_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Lower, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower or equal to
/// any in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn lte_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(LowerOrEqual, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than any
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn gt_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Greater, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal to
/// any in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn gte_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(GreaterOrEqual, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches all
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn eq_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Equal, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower than all
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn lt_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Lower, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is lower or equal to
/// all in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn lte_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(LowerOrEqual, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater than all
/// in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn gt_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Greater, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is greater or equal
/// to all in a sub-query.
///
/// NOTICE: Not supported by SQLite.
///
pub fn gte_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(GreaterOrEqual, qry)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is in a list of
/// `WhereValue`s.
///
pub fn in(value vl: WhereValue, values vals: List(WhereValue)) -> Where {
  vl |> WhereIn(vals)
}

/// Creates a `WHERE` clause that checks if it exists in a sub-query.
///
pub fn exists_in_query(sub_query qry: Query) -> Where {
  qry |> WhereExistsInSubQuery
}

/// Creates a `WHERE` clause that checks if a `WhereValue` A is between two
/// `WhereValue`s B and C.
///
pub fn between(
  value_a vl_a: WhereValue,
  value_b vl_b: WhereValue,
  value_c vl_c: WhereValue,
) -> Where {
  vl_a |> WhereBetween(vl_b, vl_c)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
/// The pattern can contain for example the following wildcards:
///
/// - `%` matches any sequence of characters.
/// - `_` matches any single character.
///
pub fn like(value vl: WhereValue, pattern pttrn: String) -> Where {
  vl |> WhereLike(pttrn)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` matches a pattern.
///
/// `ilike` is the same as `like` but case-insensitive.
///
pub fn ilike(value vl: WhereValue, pattern pttrn: String) -> Where {
  vl |> WhereILike(pttrn)
}

/// Creates a `WHERE` clause that checks if a `WhereValue` is similar to a
/// pattern.
///
/// NOTICE: Not supported by SQLite.
///
pub fn similar_to(value vl: WhereValue, to pttrn: String) -> Where {
  vl |> WhereSimilarTo(pttrn)
}

/// Creates a `WhereFragment` from a `Fragment`.
///
pub fn fragment(fragment frgmt: Fragment) -> Where {
  frgmt |> WhereFragment
}

/// Creates a `WhereValue` from a `Fragment`.
///
pub fn fragment_value(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> WhereFragmentValue
}
