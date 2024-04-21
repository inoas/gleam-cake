pub type OrderByDirectionFragment {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn to_sql(fragment: OrderByDirectionFragment) {
  case fragment {
    Asc -> "ASC NULLS LAST"
    Desc -> "DESC NULLS LAST"
    AscNullsFirst -> "ASC NULLS FIRST"
    DescNullsFirst -> "DESC NULLS FIRST"
  }
}
