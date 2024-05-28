import cake/internal/query.{type Fragment, type Where, type WhereValue}
import cake/param

pub fn col(name: String) -> WhereValue {
  name |> query.WhereColumn
}

pub fn bool(value: Bool) -> WhereValue {
  value |> param.bool |> query.WhereParam
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

pub fn and(wheres whs: List(Where)) -> Where {
  whs |> query.AndWhere
}

pub fn or(wheres whs: List(Where)) -> Where {
  whs |> query.OrWhere
}

// pub fn xor(wheres whs: List(Where)) -> Where {
//   whs |> query.XorWhere
// }

pub fn not(part: Where) -> Where {
  part |> query.NotWhere
}

pub fn eq(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereEqual(val_b)
}

pub fn lt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereLower(val_b)
}

pub fn lte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereLowerOrEqual(val_b)
}

pub fn gt(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereGreater(val_b)
}

pub fn gte(value_a val_a: WhereValue, value_b val_b: WhereValue) -> Where {
  val_a |> query.WhereGreaterOrEqual(val_b)
}

pub fn in(value val: WhereValue, values vals: List(WhereValue)) -> Where {
  val |> query.WhereIn(vals)
}

pub fn between(
  value_a val_a: WhereValue,
  value_b val_b: WhereValue,
  value_c val_c: WhereValue,
) -> Where {
  val_a |> query.WhereBetween(val_b, val_c)
}

pub fn is_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> query.WhereIsBool(b)
}

pub fn is_not_bool(value val: WhereValue, bool b: Bool) -> Where {
  val |> query.WhereIsNotBool(b)
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

pub fn like(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> query.WhereLike(pttrn)
}

pub fn ilike(value val: WhereValue, pattern pttrn: String) -> Where {
  val |> query.WhereILike(pttrn)
}

pub fn similar(value val: WhereValue, to pttrn: String) -> Where {
  val |> query.WhereSimilar(pttrn)
}

pub fn fragment(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> query.WhereFragment
}
