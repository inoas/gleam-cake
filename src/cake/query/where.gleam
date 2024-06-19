//// Used to build `WHERE` clauses for SQL queries.
//// Where clauses are used to filter rows in a table.
////
//// Also used to build `HAVING` clauses for SQL queries,
//// because they work the same way as `WHERE` clauses,
//// but are used to filter rows after `GROUP BY` has been applied.
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

pub fn float(value: Float) -> WhereValue {
  value |> param.float |> WhereParamValue
}

pub fn int(value: Int) -> WhereValue {
  value |> param.int |> WhereParamValue
}

pub fn string(value: String) -> WhereValue {
  value |> param.string |> WhereParamValue
}

pub fn not(part: Where) -> Where {
  part |> NotWhere
}

pub fn and(wheres whs: List(Where)) -> Where {
  whs |> AndWhere
}

pub fn or(wheres whs: List(Where)) -> Where {
  whs |> OrWhere
}

pub fn xor(wheres whs: List(Where)) -> Where {
  whs |> XorWhere
}

pub fn is_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> WhereIsBool(b)
}

pub fn is_not_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> WhereIsNotBool(b)
}

pub fn is_false(value val: WhereValue) -> Where {
  val |> WhereIsBool(False)
}

pub fn is_true(value val: WhereValue) -> Where {
  val |> WhereIsBool(True)
}

pub fn is_not(value val: WhereValue, bool b: Bool) -> Where {
  val |> WhereIsNotBool(b)
}

pub fn is_null(value val: WhereValue) -> Where {
  val |> WhereIsNull
}

pub fn is_not_null(value val: WhereValue) -> Where {
  val |> WhereIsNotNull
}

pub fn eq(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> WhereComparison(Equal, val_b)
}

pub fn lt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> WhereComparison(Lower, val_b)
}

pub fn lte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> WhereComparison(LowerOrEqual, val_b)
}

pub fn gt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> WhereComparison(Greater, val_b)
}

pub fn gte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> WhereComparison(GreaterOrEqual, val_b)
}

/// NOTICE: Not supported by SQLite.
///
pub fn eq_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAnyOfSubQuery(Equal, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAnyOfSubQuery(Lower, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAnyOfSubQuery(LowerOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAnyOfSubQuery(Greater, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAnyOfSubQuery(GreaterOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn eq_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAllOfSubQuery(Equal, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAllOfSubQuery(Lower, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn lte_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAllOfSubQuery(LowerOrEqual, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAllOfSubQuery(Greater, qry)
}

/// NOTICE: Not supported by SQLite.
///
pub fn gte_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> WhereAllOfSubQuery(GreaterOrEqual, qry)
}

pub fn in(value val: WhereValue, values vals: List(WhereValue)) -> Where {
  val |> WhereIn(vals)
}

pub fn exists_in_query(sub_query qry: Query) -> Where {
  qry |> WhereExistsInSubQuery
}

pub fn between(
  value_a val_a: WhereValue,
  value_b val_b: WhereValue,
  value_c val_c: WhereValue,
) -> Where {
  val_a |> WhereBetween(val_b, val_c)
}

pub fn like(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> WhereLike(pttrn)
}

/// `ILIKE` is the same as `LIKE` but case-insensitive.
///
pub fn ilike(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> WhereILike(pttrn)
}

/// NOTICE: Not supported by SQLite.
///
pub fn similar_to(value val: WhereValue, to pttrn: String) -> Where {
  val |> WhereSimilarTo(pttrn)
}

pub fn fragment(fragment frgmt: Fragment) -> Where {
  frgmt |> WhereFragment
}

pub fn value_fragment(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> WhereFragmentValue
}
