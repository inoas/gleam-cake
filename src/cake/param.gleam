pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  NullParam
}
// import gleam/float
// import gleam/int

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
