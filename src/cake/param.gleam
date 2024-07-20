//// A `Param` is a value that can be used in a query.
////

// TODO v2 how to create DECIMAL, DATE, TIME and DATETIME

/// Params (e.g. parameters) are wrapped (boxed) literal values, that can be
/// used in SQL queries.
///
pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  NullParam
  //
  // Not sure this should be here, but should it not?
  // Maybe add:
  // DecimalParam(Int, Int) TODO v2
  // JsonParam(String)
  // XmlParam(String)
  // UuidParam(String)
  // BinaryParam(any)
  // DateParam(year: Int, month: Int, day: Int)
  // TimeParam(hour: Int, minute: Int, second: Int)
  // Time6Param(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)
  // DateTimeParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
  // DateTime6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int))
  // UnixTimeStampParam(Int)
  // DateTzParam(year: Int, month: Int, day: Int, timezone: String)
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
pub fn bool(value vl: Bool) -> Param {
  vl |> BoolParam
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
//
// // This should ONLY be used for debugging purposes
// // not to ever run actual queries.
// pub fn to_debug(param: Param) -> String {
//   case param {
//     BoolParam(True) -> "TRUE"
//     BoolParam(False) -> "FALSE"
//     FloatParam(value) -> float.to_string(value)
//     IntParam(value) -> int.to_string(value)
//     // TODO: no injection
//     StringParam(value) -> "'" <> value <> "'"
//     NullParam -> "NULL"
//   }
// }
