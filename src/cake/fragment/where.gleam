import gleam/float
import gleam/int
import gleam/list
import gleam/pair
import pprint.{debug as dbg}

pub type WhereFragment {
  // Column A to column B comparison
  ColEqualCol(a_column: String, b_column: String)
  ColLowerCol(a_column: String, b_column: String)
  ColLowerOrEqualCol(a_column: String, b_column: String)
  ColGreaterCol(a_column: String, b_column: String)
  ColGreaterOrEqualCol(a_column: String, b_column: String)
  ColNotEqualCol(a_column: String, b_column: String)
  // Column to parameter comparison
  ColEqualParam(column: String, parameter: Param)
  ColLowerParam(column: String, parameter: Param)
  ColLowerOrEqualParam(column: String, parameter: Param)
  ColGreaterParam(column: String, parameter: Param)
  ColGreaterOrEqualParam(column: String, parameter: Param)
  ColNotEqualParam(column: String, parameter: Param)
  // Parameter to column comparison
  ParamEqualCol(parameter: Param, column: String)
  ParamLowerCol(parameter: Param, column: String)
  ParamLowerOrEqualCol(parameter: Param, column: String)
  ParamGreaterCol(parameter: Param, column: String)
  ParamGreaterOrEqualCol(parameter: Param, column: String)
  ParamEqualNotCol(parameter: Param, column: String)
  // Logical operators
  AndWhere(fragments: List(WhereFragment))
  NotWhere(fragments: List(WhereFragment))
  OrWhere(fragments: List(WhereFragment))
  // XorWhere(List(WhereFragment))
  // Column contains value
  ColInParams(column: String, parameters: List(Param))
}

pub type Null

pub type Param {
  BoolParam(Bool)
  FloatParam(Float)
  IntParam(Int)
  StringParam(String)
  NullParam
}

type Prepared =
  #(String, List(Param))

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
pub fn to_prepared_sql(fragment frgmt: WhereFragment) -> Prepared {
  case frgmt {
    ColEqualCol(a_col, b_col) -> #(a_col <> " = " <> b_col, [])
    ColLowerCol(a_col, b_col) -> #(a_col <> " < " <> b_col, [])
    ColLowerOrEqualCol(a_col, b_col) -> #(a_col <> " <= " <> b_col, [])
    ColGreaterCol(a_col, b_col) -> #(a_col <> " > " <> b_col, [])
    ColGreaterOrEqualCol(a_col, b_col) -> #(a_col <> " >= " <> b_col, [])
    ColNotEqualCol(a_col, b_col) -> #(a_col <> " <> " <> b_col, [])
    ColEqualParam(col, NullParam) -> #(col <> " IS NULL", [])
    ColEqualParam(col, param) -> #(col <> " = ?", [param])
    ColLowerParam(col, param) -> #(col <> " < ?", [param])
    ColLowerOrEqualParam(col, param) -> #(col <> " <= ?", [param])
    ColGreaterParam(col, param) -> #(col <> " > ? ", [param])
    ColGreaterOrEqualParam(col, param) -> #(col <> " >= ? ", [param])
    ColNotEqualParam(col, NullParam) -> #(col <> " IS NOT NULL", [])
    ColNotEqualParam(col, param) -> #(col <> " <> ? ", [param])
    ParamEqualCol(NullParam, col) -> #(col <> "IS NULL", [])
    ParamEqualCol(param, col) -> #("? = " <> col, [param])
    ParamLowerCol(param, col) -> #("? < " <> col, [param])
    ParamLowerOrEqualCol(param, col) -> #("? <= " <> col, [param])
    ParamGreaterCol(param, col) -> #("? > " <> col, [param])
    ParamGreaterOrEqualCol(param, col) -> #("? >= " <> col, [param])
    ParamEqualNotCol(NullParam, col) -> #(col <> " IS NOT NULL", [])
    ParamEqualNotCol(param, col) -> #("? <> " <> col, [param])
    AndWhere(frgmts) -> apply_logical_sql_operator(frgmts, "AND")
    NotWhere(frgmts) -> apply_logical_sql_operator(frgmts, "NOT")
    OrWhere(frgmts) -> apply_logical_sql_operator(frgmts, "OR")
    ColInParams(col, params) -> apply_column_in_params(col, params)
  }
}

fn apply_logical_sql_operator(fragments: List(WhereFragment), operator: String) {
  fragments
  |> list.fold(
    #("", []),
    fn(acc: Prepared, fragment: WhereFragment) -> Prepared {
      let prepared = to_prepared_sql(fragment)
      let new_string = case acc.0 {
        "" -> prepared.0
        _ -> acc.0 <> " " <> operator <> " " <> prepared.0
      }
      let new_params = list.append(acc.1, prepared.1)
      #(new_string, new_params)
    },
  )
  |> pair.map_first(fn(string) { "(" <> string <> ")" })
}

fn apply_column_in_params(col: String, params: List(Param)) -> Prepared {
  params
  |> list.fold(#("", []), fn(acc: Prepared, param: Param) -> Prepared {
    let new_string = case acc.0 {
      "" -> "?"
      _ -> acc.0 <> ", ?"
    }
    let new_params = list.append(acc.1, [param])
    #(new_string, new_params)
  })
  |> pair.map_first(fn(string) { col <> " IN (" <> string <> ")" })
}

pub fn to_sql(fragment frgmt: WhereFragment) -> String {
  frgmt
  |> to_prepared_sql()
  |> dbg
  |> pair.first()
  // TODO: insert values here
}

// TODO: Move this to prepared statements and use question marks then,
// ... or at least optionally though.
fn param_to_sql(param: Param) -> String {
  case param {
    BoolParam(True) -> "TRUE"
    BoolParam(False) -> "FALSE"
    FloatParam(value) -> float.to_string(value)
    IntParam(value) -> int.to_string(value)
    StringParam(value) -> "'" <> value <> "'"
    NullParam -> "NULL"
  }
}
