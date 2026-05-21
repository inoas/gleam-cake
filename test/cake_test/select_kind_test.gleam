import cake/internal/read_query
import cake/select as s

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Unit Tests                                                                │
// └───────────────────────────────────────────────────────────────────────────┘

/// A freshly created `Select` query defaults to `SelectAll`.
///
pub fn get_kind_default_is_all_test() {
  assert s.new() |> s.get_kind == read_query.SelectAll
}

/// `distinct` sets the kind to `SelectDistinct`; `get_kind` must reflect that.
///
pub fn get_kind_after_distinct_test() {
  assert s.new() |> s.distinct |> s.get_kind == read_query.SelectDistinct
}

/// `all` sets the kind to `SelectAll`; `get_kind` must reflect that even after
/// a prior call to `distinct`.
///
pub fn get_kind_after_all_test() {
  assert s.new() |> s.distinct |> s.all |> s.get_kind == read_query.SelectAll
}
