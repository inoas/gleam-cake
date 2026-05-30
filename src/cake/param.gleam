//// A `Param` is a value that can be used in a query.
////

import gleam/time/calendar

// TODO v3 how to create DECIMAL, TIME and DATETIME

/// Params (e.g. parameters) are wrapped (boxed) literal values, that can be
/// used in SQL queries.
///
pub type Param {
  StringParam(value: String)
  IntParam(value: Int)
  FloatParam(value: Float)
  NullParam
  BoolParam(value: Bool)
  DateParam(value: calendar.Date)
  //
  // Not sure this should be here, but should it not?
  // Maybe add:
  // DecimalParam(Int, Int) TODO v2
  // JsonParam(String)
  // XmlParam(String)
  // UuidParam(String)
  // BinaryParam(any)
  // TimeParam(hour: Int, minute: Int, second: Int)
  // Time6Param(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)
  // DateTimeParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
  // DateTime6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int))
  // UnixTimeStampParam(Int)
  // TimeTzParam(hour: Int, minute: Int, second: Int, timezone: String)
  // Time6TzParam(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int), timezone: String)
  // DateTimeTzParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, timezone: String)
  // DateTimeTz6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int), timezone: String)
  // UnixTimeStampParam(Int)
  // BinaryParam(any)
  // UuidParam(String)
  // ArrayParam(Param)
  // ObjectParam(String, Param)
  // XmlParam(String)
  // CustomParam(encoder_fn: Function(custom), custom)
}

/// Create a new `Param` with a `Bool` value.
///
pub fn bool(value: Bool) -> Param {
  value |> BoolParam
}

/// Create a new `Param` with a `Float` value.
///
pub fn float(value: Float) -> Param {
  value |> FloatParam
}

/// Create a new `Param` with an `Int` value.
///
pub fn int(value: Int) -> Param {
  value |> IntParam
}

/// Create a new `Param` with a `String` value.
///
pub fn string(value: String) -> Param {
  value |> StringParam
}

/// Create a new `Param` with an SQL `NULL` value.
///
pub fn null() -> Param {
  NullParam
}

/// Create a new `Param` with a `calendar.Date` value.
///
pub fn date(value: calendar.Date) -> Param {
  value |> DateParam
}
//
// import cake/param
// import gleam/float
// import gleam/int
// import gleam/string
// import gleam/time/calendar

// pub fn debug(param: param.Param) -> String {
//   case param {
//     param.StringParam(value:) -> "'" <> value <> "'"
//     param.IntParam(value:) -> int.to_string(value)
//     param.FloatParam(value:) -> float.to_string(value)
//     param.BoolParam(True) -> "TRUE"
//     param.BoolParam(False) -> "FALSE"
//     param.NullParam -> "NULL"
//     param.DateParam(calendar.Date(year:, month:, day:)) -> {
//       let year =
//         year
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 4)
//       let month =
//         month
//         |> calendar.month_to_int
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 2)
//       let day =
//         day
//         |> int.to_string
//         |> string.pad_start(with: "0", to: 2)
//       "SQL: " <> year <> "-" <> month <> "-" <> day
//     }
//   }
// }
