pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  // NullParam
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
