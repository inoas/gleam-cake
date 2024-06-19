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

import cake/internal/query.{
  type Fragment, type Query, type Where, type WhereValue, AndWhere, Equal,
  Greater, GreaterOrEqual, Lower, LowerOrEqual, NotWhere, OrWhere,
  WhereAllOfSubQuery, WhereAnyOfSubQuery, WhereBetween, WhereColumnValue,
  WhereComparison, WhereExistsInSubQuery, WhereFragment, WhereFragmentValue,
  WhereILike, WhereIn, WhereIsBool, WhereIsNotBool, WhereIsNotNull, WhereIsNull,
  WhereLike, WhereParamValue, WhereSimilarTo, XorWhere,
}
import cake/param

pub fn col(name: String) -> WhereValue {
  name |> WhereColumnValue
}

pub fn float(v vl: Float) -> WhereValue {
  vl |> param.float |> WhereParamValue
}

pub fn int(v vl: Int) -> WhereValue {
  vl |> param.int |> WhereParamValue
}

pub fn string(v vl: String) -> WhereValue {
  vl |> param.string |> WhereParamValue
}

pub fn not(where whr: Where) -> Where {
  whr |> NotWhere
}

pub fn and(wheres whrs: List(Where)) -> Where {
  whrs |> AndWhere
}

pub fn or(wheres whrs: List(Where)) -> Where {
  whrs |> OrWhere
}

pub fn xor(wheres whrs: List(Where)) -> Where {
  whrs |> XorWhere
}

pub fn is_bool(value vl: WhereValue, bool b: Bool) -> Where {
  vl |> WhereIsBool(b)
}

pub fn is_not_bool(value vl: WhereValue, bool b: Bool) -> Where {
  vl |> WhereIsNotBool(b)
}

pub fn is_false(value vl: WhereValue) -> Where {
  vl |> WhereIsBool(False)
}

pub fn is_true(value vl: WhereValue) -> Where {
  vl |> WhereIsBool(True)
}

pub fn is_not(value vl: WhereValue, bool b: Bool) -> Where {
  vl |> WhereIsNotBool(b)
}

pub fn is_null(value vl: WhereValue) -> Where {
  vl |> WhereIsNull
}

pub fn is_not_null(value vl: WhereValue) -> Where {
  vl |> WhereIsNotNull
}

pub fn eq(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Equal, vl_b)
}

pub fn lt(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Lower, vl_b)
}

pub fn lte(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(LowerOrEqual, vl_b)
}

pub fn gt(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(Greater, vl_b)
}

pub fn gte(value_a vl_a: WhereValue, value_b vl_b: WhereValue) -> Where {
  vl_a |> WhereComparison(GreaterOrEqual, vl_b)
}

/// NOTICE: Not supported by SQLite.
///
pub fn eq_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Equal, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lt_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Lower, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lte_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(LowerOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gt_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(Greater, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gte_any_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAnyOfSubQuery(GreaterOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn eq_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Equal, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lt_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Lower, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lte_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(LowerOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gt_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(Greater, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gte_all_query(value vl: WhereValue, sub_query qry: Query) -> Where {
  vl |> WhereAllOfSubQuery(GreaterOrEqual, qry)
}

pub fn in(value vl: WhereValue, values vals: List(WhereValue)) -> Where {
  vl |> WhereIn(vals)
}

pub fn exists_in_query(sub_query qry: Query) -> Where {
  qry |> WhereExistsInSubQuery
}

pub fn between(
  value_a vl_a: WhereValue,
  value_b vl_b: WhereValue,
  value_c vl_c: WhereValue,
) -> Where {
  vl_a |> WhereBetween(vl_b, vl_c)
}

pub fn like(value vl: WhereValue, pattern pttrn: String) -> Where {
  vl |> WhereLike(pttrn)
}

/// `ILIKE` is the same as `LIKE` but case-insensitive.
///
pub fn ilike(value vl: WhereValue, pattern pttrn: String) -> Where {
  vl |> WhereILike(pttrn)
}

/// NOTICE: Not supported by SQLite.
///
pub fn similar_to(value vl: WhereValue, to pttrn: String) -> Where {
  vl |> WhereSimilarTo(pttrn)
}

pub fn fragment(fragment frgmt: Fragment) -> Where {
  frgmt |> WhereFragment
}

pub fn fragment_value(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> WhereFragmentValue
}
