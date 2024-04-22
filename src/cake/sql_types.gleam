import gleam/float
import gleam/int

pub type PreparedStatement =
  #(String, List(Param))

pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  NullParam
}

// TODO: Move this to prepared statements and use question marks then,
// ... or at least optionally though.
pub fn param_to_sql(param: Param) -> String {
  case param {
    BoolParam(True) -> "TRUE"
    BoolParam(False) -> "FALSE"
    FloatParam(value) -> float.to_string(value)
    IntParam(value) -> int.to_string(value)
    // TODO: no injection
    StringParam(value) -> "'" <> value <> "'"
    NullParam -> "NULL"
  }
}
