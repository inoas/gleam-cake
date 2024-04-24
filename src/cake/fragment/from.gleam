pub type FromFragment {
  FromFragment(String)
  NoFromFragment
}

pub fn to_sql(fragment frgmt: FromFragment) {
  case frgmt {
    FromFragment(s) -> " FROM " <> s
    NoFromFragment -> ""
  }
}
