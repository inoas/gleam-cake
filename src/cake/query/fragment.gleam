import cake/internal/query.{type Fragment}
import cake/param.{type Param}

pub const placeholder = query.fragment_placeholder

pub fn literal(literal: String) -> Fragment {
  query.FragmentLiteral(literal)
}

pub fn prepared(literal: String, param: Param) -> Fragment {
  query.FragmentPrepared(literal, param)
}
