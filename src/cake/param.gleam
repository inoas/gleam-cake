pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  // NullParam // <= Not sure we want this
  //
  // Maybe add:
  // JsonParam(String)
  // XmlParam(String)
  // UuidParam(String)
  // BinaryParam(any)
  // DateParam(year: Int, month: Int, day: Int)
  // TimeParam(hour: Int, minute: Int, second: Int)
  // Time6Param(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)
  // DateTimeParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int)
  // DateTime6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)))))
  // UnixTimeStampParam(Int)
  // DateTzParam(year: Int, month: Int, day: Int, timezone: String)
  // TimeTzParam(hour: Int, minute: Int, second: Int, timezone: String)
  // Time6TzParam(hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int), timezone: String)
  // DateTimeTzParam(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, timezone: String)
  // DateTimeTz6Param(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, fraction: #(Int, Int, Int, Int, Int, Int)))), timezone: String)
  // UnixTimeStampParam(Int)
  // BinaryParam(any)
  // UuidParam(String)
  // ArrayParam(Param)
  // ObjectParam(String, Param)
  // XmlParam(String)
  // CustomParam(caster_fn: Function(custom), custom)
}

pub fn bool(value: Bool) -> Param {
  BoolParam(value)
}

pub fn float(value: Float) -> Param {
  FloatParam(value)
}

pub fn int(value: Int) -> Param {
  IntParam(value)
}

pub fn string(value: String) -> Param {
  StringParam(value)
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
