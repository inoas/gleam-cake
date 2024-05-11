import cake/internal/query.{type Fragment}
import cake/param.{type Param}

import cake/stdlib/iox

pub const placeholder = query.fragment_placeholder

pub fn literal(string str: String) -> Fragment {
  str |> query.FragmentLiteral()
}

pub fn prepared(string str: String, param prm: Param) -> Fragment {
  let parts = query.fragment_prepared_split_string(str)
  let placeholder_count = parts |> query.fragment_prepared_count_placeholders

  iox.dbg(str)
  iox.dbg(placeholder_count)

  case placeholder_count {
    0 -> query.FragmentLiteral(str)
    1 -> query.FragmentPrepared(str, prm)
    _n -> query.FragmentPrepared(str, prm)
    // _n -> panic as "prepared fragment with more than one placeholder"
  }
}
