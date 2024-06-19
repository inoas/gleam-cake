// TODO v1 module doc
// TODO v1 tests

import cake/internal/query.{
  type Fragment, type Query, type Where, type WhereValue, Equal, Greater,
  GreaterOrEqual, Lower, LowerOrEqual, WhereFragment,
}
import cake/param

pub fn col(name: String) -> WhereValue {
  name |> query.WhereColumnValue
}

pub fn float(value: Float) -> WhereValue {
  value |> param.float |> query.WhereParamValue
}

pub fn int(value: Int) -> WhereValue {
  value |> param.int |> query.WhereParamValue
}

pub fn string(value: String) -> WhereValue {
  value |> param.string |> query.WhereParamValue
}

pub fn not(part: Where) -> Where {
  part |> query.NotWhere
}

pub fn and(wheres whs: List(Where)) -> Where {
  whs |> query.AndWhere
}

pub fn or(wheres whs: List(Where)) -> Where {
  whs |> query.OrWhere
}

// TODO v1
// pub fn xor(wheres whs: List(Where)) -> Where {
//   whs |> query.XorWhere
// }

pub fn is_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> query.WhereIsBool(b)
}

pub fn is_not_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> query.WhereIsNotBool(b)
}

pub fn is_false(value val: WhereValue) -> Where {
  val |> query.WhereIsBool(False)
}

pub fn is_true(value val: WhereValue) -> Where {
  val |> query.WhereIsBool(True)
}

pub fn is_not(value val: WhereValue, bool b: Bool) -> Where {
  val |> query.WhereIsNotBool(b)
}

pub fn is_null(value val: WhereValue) -> Where {
  val |> query.WhereIsNull
}

pub fn is_not_null(value val: WhereValue) -> Where {
  val |> query.WhereIsNotNull
}

pub fn eq(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereComparison(Equal, val_b)
}

pub fn lt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereComparison(Lower, val_b)
}

pub fn lte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereComparison(LowerOrEqual, val_b)
}

pub fn gt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereComparison(Greater, val_b)
}

pub fn gte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereComparison(GreaterOrEqual, val_b)
}

/// Notice: Not supported by SQLite
///
pub fn eq_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Equal, qry)
}

/// Notice: Not supported by SQLite
///
pub fn lt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Lower, qry)
}

/// Notice: Not supported by SQLite
///
pub fn lte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(LowerOrEqual, qry)
}

/// Notice: Not supported by SQLite
///
pub fn gt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Greater, qry)
}

/// Notice: Not supported by SQLite
///
pub fn gte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(GreaterOrEqual, qry)
}

/// Notice: Not supported by SQLite
///
pub fn eq_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Equal, qry)
}

/// Notice: Not supported by SQLite
///
pub fn lt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Lower, qry)
}

/// Notice: Not supported by SQLite
///
pub fn lte_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(LowerOrEqual, qry)
}

/// Notice: Not supported by SQLite
///
pub fn gt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Greater, qry)
}

/// Notice: Not supported by SQLite
///
pub fn gte_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(GreaterOrEqual, qry)
}

pub fn in(value val: WhereValue, values vals: List(WhereValue)) -> Where {
  val |> query.WhereIn(vals)
}

pub fn exists_in_query(sub_query qry: Query) -> Where {
  qry |> query.WhereExistsInSubQuery
}

pub fn between(
  value_a val_a: WhereValue,
  value_b val_b: WhereValue,
  value_c val_c: WhereValue,
) -> Where {
  val_a |> query.WhereBetween(val_b, val_c)
}

pub fn like(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> query.WhereLike(pttrn)
}

/// `ILIKE` is the same as `LIKE` but case-insensitive.
///
pub fn ilike(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> query.WhereILike(pttrn)
}

/// Notice: Not supported by SQLite
///
pub fn similar_to(value val: WhereValue, to pttrn: String) -> Where {
  val |> query.WhereSimilarTo(pttrn)
}

pub fn fragment(fragment frgmt: Fragment) -> Where {
  frgmt |> WhereFragment
}

pub fn value_fragment(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> query.WhereFragmentValue
}
