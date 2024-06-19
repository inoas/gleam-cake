// TODO v1 module doc
// TODO v1 tests

import cake/internal/query.{
  type Fragment, type Query, type Where, type WhereValue, Equal, Greater,
  GreaterOrEqual, Lower, LowerOrEqual, RawWhereFragment,
}
import cake/param

pub fn col(name: String) -> WhereValue {
  name |> query.WhereColumn
}

pub fn float(value: Float) -> WhereValue {
  value |> param.float |> query.WhereParam
}

pub fn int(value: Int) -> WhereValue {
  value |> param.int |> query.WhereParam
}

pub fn string(value: String) -> WhereValue {
  value |> param.string |> query.WhereParam
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

pub fn eq_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Equal, qry)
}

pub fn lt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Lower, qry)
}

pub fn lte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(LowerOrEqual, qry)
}

pub fn gt_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(Greater, qry)
}

pub fn gte_any_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAnyOfSubQuery(GreaterOrEqual, qry)
}

pub fn eq_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Equal, qry)
}

pub fn lt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Lower, qry)
}

pub fn lte_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(LowerOrEqual, qry)
}

pub fn gt_all_query(value val: WhereValue, sub_query qry: Query) -> Where {
  val |> query.WhereAllOfSubQuery(Greater, qry)
}

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

pub fn similar(value val: WhereValue, to pttrn: String) -> Where {
  val |> query.WhereSimilar(pttrn)
}

pub fn fragment(fragment frgmt: Fragment) -> Where {
  frgmt |> RawWhereFragment
}

pub fn value_fragment(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> query.WhereFragment
}
