import cake/internal/query.{type Fragment}
import cake/param.{type Param}
import gleam/int
import gleam/io
import gleam/list
import gleam/order

pub const placeholder = query.fragment_placeholder_grapheme

pub fn literal(string str: String) -> Fragment {
  str |> query.FragmentLiteral()
}

pub fn prepared(string str: String, params prms: List(Param)) -> Fragment {
  let plchldr_count =
    str
    |> query.fragment_prepared_split_string
    |> query.fragment_count_placeholders

  let param_count = prms |> list.length

  case plchldr_count, param_count, plchldr_count |> int.compare(param_count) {
    0, 0, order.Eq -> {
      str |> query.FragmentLiteral()
    }
    _n, _n, order.Eq -> {
      str |> query.FragmentPrepared(prms)
    }
    0, _n, _not_eq -> {
      io.println_error(
        "Fragment had 0 "
        <> placeholder
        <> "-placeholders, but there were "
        <> int.to_string(param_count)
        <> " params given!",
      )
      str |> query.FragmentLiteral()
    }
    _n, 0, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> int.to_string(plchldr_count)
        <> " "
        <> placeholder
        <> "-placeholders, but there were 0 params given!",
      )
      str |> query.FragmentLiteral()
    }
    _n, _m, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> int.to_string(plchldr_count)
        <> " "
        <> placeholder
        <> "-placeholders, but there were "
        <> int.to_string(param_count)
        <> " params given!",
      )
      str |> query.FragmentPrepared(prms)
    }
  }
}
