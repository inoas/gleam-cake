//// Fragments are low level building blocks of queries which allow direct
//// manipulation of the query string.
////
//// If you want to insert parameters, you are required to use prepared
//// fragments, which will be validated against the number of parameters given
//// and the parameters are automatically escaped by the RDBMS to prevent SQL
//// injections.
////

import cake/internal/read_query
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/int
import gleam/io
import gleam/list
import gleam/order

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  read_query type re-exports                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Fragment =
  read_query.Fragment

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  fragment                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

/// This placeholder must be used when building fragments with parameters.
///
pub const placeholder = read_query.fragment_placeholder_grapheme

/// Create a new fragment from a string and a list of parameters.
///
/// ⛔ ⛔ ⛔
///
/// If you missmatch the number of placeholders with the number of
/// parameters, an error will be printed to stderr and the fragment will be
/// created with the given parameters:
///
/// - If there are too many placeholders, the fragment will be created with the
///   given parameters and the last parameter will be repeated for the remaining
///   placeholders.
/// - If there are too many parameters, the fragment will be created with the
///   given parameters and the excess parameters will be ignored.
///
/// ⛔ ⛔ ⛔
///
pub fn prepared(string str: String, params prms: List(Param)) -> Fragment {
  let plchldr_count =
    str
    |> read_query.fragment_prepared_split_string
    |> read_query.fragment_count_placeholders

  let param_count = prms |> list.length

  case plchldr_count, param_count, plchldr_count |> int.compare(param_count) {
    0, 0, order.Eq -> {
      str |> read_query.FragmentLiteral
    }
    _n, _n, order.Eq -> {
      str |> read_query.FragmentPrepared(prms)
    }
    0, _n, _not_eq -> {
      io.println_error(
        "Fragment had 0 "
        <> placeholder
        <> "-placeholders, but there were "
        <> param_count |> int.to_string
        <> " params given!",
      )
      str |> read_query.FragmentLiteral
    }
    _n, 0, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> plchldr_count |> int.to_string
        <> " "
        <> placeholder
        <> "-placeholders, but there were 0 params given!",
      )
      str |> read_query.FragmentLiteral
    }
    _n, _m, _not_eq -> {
      io.println_error(
        "Fragment had "
        <> plchldr_count |> int.to_string
        <> " "
        <> placeholder
        <> "-placeholders, but there were "
        <> param_count |> int.to_string
        <> " params given!",
      )
      str |> read_query.FragmentPrepared(prms)
    }
  }
}

/// Create a new fragment from a literal string.
///
/// ⛔ ⛔ ⛔
///
/// WARNING: YOU ARE FORBIDDEN TO INSERT UNCONTROLLED USER INPUT THIS WAY!
///
/// ⛔ ⛔ ⛔
///
pub fn literal(string str: String) -> Fragment {
  str |> read_query.FragmentLiteral
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  params                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Create a new `Param` with a `Bool` value.
///
pub fn bool(value vl: Bool) -> Param {
  vl |> BoolParam
}

/// Create a new `Param` with a `True` value.
///
pub fn true() -> Param {
  True |> BoolParam
}

/// Create a new `Param` with a `True` value.
///
pub fn false() -> Param {
  False |> BoolParam
}

/// Create a new `Param` with a `Float` value.
///
pub fn float(value vl: Float) -> Param {
  vl |> FloatParam
}

/// Create a new `Param` with an `Int` value.
///
pub fn int(value vl: Int) -> Param {
  vl |> IntParam
}

/// Create a new `Param` with a `String` value.
///
pub fn string(value vl: String) -> Param {
  vl |> StringParam
}

/// Create a new `Param` with an SQL `NULL` value.
///
pub fn null() -> Param {
  NullParam
}
