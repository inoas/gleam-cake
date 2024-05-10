import cake/internal/query.{type Fragment, type WherePart, type WhereValue}
import cake/param
import cake/query/comparison.{type Comparison}

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

pub fn and(parts: List(WherePart)) -> WherePart {
  parts |> query.AndWhere
}

pub fn or(parts: List(WherePart)) -> WherePart {
  parts |> query.OrWhere
}

pub fn not(part: WherePart) -> WherePart {
  part |> query.NotWhere
}

pub fn cond(
  value_a val_a: WhereValue,
  operator oprtr: Comparison,
  value_b val_b: WhereValue,
) -> WherePart {
  case oprtr {
    comparison.EQ -> eq(val_a, val_b)
    comparison.GT -> gt(val_a, val_b)
    comparison.GTE -> gte(val_a, val_b)
    comparison.LT -> lt(val_a, val_b)
    comparison.LTE -> lte(val_a, val_b)
  }
}

pub fn eq(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  value_a |> query.WhereEqual(value_b)
}

pub fn lt(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  value_a |> query.WhereLower(value_b)
}

pub fn lte(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  value_a |> query.WhereLowerOrEqual(value_b)
}

pub fn gt(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  value_a |> query.WhereGreater(value_b)
}

pub fn gte(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  value_a |> query.WhereGreaterOrEqual(value_b)
}

pub fn in(value: WhereValue, values: List(WhereValue)) -> WherePart {
  value |> query.WhereIn(values)
}

pub fn like(value: WhereValue, pattern: String) -> WherePart {
  query.WhereLike(value, pattern)
}

pub fn ilike(value: WhereValue, pattern: String) -> WherePart {
  query.WhereILike(value, pattern)
}

pub fn fragment(fragment frgmt: Fragment) -> WhereValue {
  frgmt |> query.WhereFragments([])
}

pub fn fragments(
  fragment frgmt: Fragment,
  fragments frgmts: List(Fragment),
) -> WhereValue {
  query.WhereFragments(frgmt, frgmts)
}
