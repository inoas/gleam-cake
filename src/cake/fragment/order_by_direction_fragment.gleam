pub type OrderByDirectionFragment {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

pub fn order_by_direction_fragment_to_sql(
  fragment frgmt: OrderByDirectionFragment,
) {
  case frgmt {
    Asc -> " ASC NULLS LAST"
    Desc -> " DESC NULLS LAST"
    AscNullsFirst -> " ASC NULLS FIRST"
    DescNullsFirst -> " DESC NULLS FIRST"
  }
}
