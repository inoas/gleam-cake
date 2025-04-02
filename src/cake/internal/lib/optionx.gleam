import gleam/option.{type Option, None, Some}

/// Used to apply an option to a builder function
/// If Some is set the builder function is run, otherwise it is omitted
/// and the builder value is simply returned.
///
/// ## Example
///
/// ```gleam
/// import cake_shork/internal/lib/optionx
///
/// let connection =
///   shork.default_config()
///   |> shork.host(host)
///   |> shork.port(port)
///   |> optionx.apply(username, shork.user)
///   |> shork.connect
/// ```
///
pub fn apply(
  builder builder: a,
  option option: Option(b),
  function function: fn(a, b) -> a,
) -> a {
  case option {
    Some(value) -> builder |> function(value)
    None -> builder
  }
}
