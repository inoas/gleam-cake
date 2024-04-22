pub type OrderByDirectionFragment {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn to_sql(fragment frgmt: OrderByDirectionFragment) {
  case frgmt {
    Asc -> "ASC NULLS LAST"
    Desc -> "DESC NULLS LAST"
    AscNullsFirst -> "ASC NULLS FIRST"
    DescNullsFirst -> "DESC NULLS FIRST"
  }
}
