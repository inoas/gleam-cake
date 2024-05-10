import cake/internal/query.{type Fragment, type WherePart, type WhereValue}
import cake/param.{type Param}
import cake/query/comparison.{type Comparison}

// pub type Value =
//   query.WhereValue

// pub type Part =
//   query.WherePart

pub fn col(name: String) -> WhereValue {
  query.WhereColumn(name)
}

pub fn param(param: Param) -> WhereValue {
  query.WhereParam(param)
}

pub fn bool(value: Bool) -> WhereValue {
  value |> param.bool |> param
}

pub fn float(value: Float) -> WhereValue {
  value |> param.float |> param
}

pub fn int(value: Int) -> WhereValue {
  value |> param.int |> param
}

pub fn string(value: String) -> WhereValue {
  value |> param.string |> param
}

pub fn and(parts: List(WherePart)) -> WherePart {
  query.AndWhere(parts)
}

pub fn or(parts: List(WherePart)) -> WherePart {
  query.OrWhere(parts)
}

pub fn not(part: WherePart) -> WherePart {
  query.NotWhere(part)
}

pub fn eq(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  query.WhereEqual(value_a, value_b)
}

pub fn lt(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  query.WhereLower(value_a, value_b)
}

pub fn lte(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  query.WhereLowerOrEqual(value_a, value_b)
}

pub fn gt(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  query.WhereGreater(value_a, value_b)
}

pub fn gte(value_a: WhereValue, value_b: WhereValue) -> WherePart {
  query.WhereGreaterOrEqual(value_a, value_b)
}

pub fn in(value: WhereValue, values: List(WhereValue)) -> WherePart {
  query.WhereIn(value, values)
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

pub fn like(value: WhereValue, pattern: String) -> WherePart {
  query.WhereLike(value, pattern)
}

pub fn ilike(value: WhereValue, pattern: String) -> WherePart {
  query.WhereILike(value, pattern)
}

pub fn fragment(fragment frgmt: Fragment) -> WhereValue {
  query.WhereFragments(frgmt, [])
}

pub fn fragments(
  fragment frgmt: Fragment,
  fragments frgmts: List(Fragment),
) -> WhereValue {
  query.WhereFragments(frgmt, frgmts)
}
