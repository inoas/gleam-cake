import gleam/float
import gleam/int
import gleam/list
import gleam/pair

pub type WhereFragment {
  // Column A to B comparison
  ColumnEqualColumn(a_column: String, b_column: String)
  ColumnLowerColumn(a_column: String, b_column: String)
  ColumnLowerOrEqualColumn(a_column: String, b_column: String)
  ColumnGreaterColumn(a_column: String, b_column: String)
  ColumnGreaterOrEqualColumn(a_column: String, b_column: String)
  ColumnNotEqualColumn(a_column: String, b_column: String)
  // Column to Literal comparison
  ColumnEqualLiteral(column: String, literal: Literal)
  ColumnLowerLiteral(column: String, literal: Literal)
  ColumnLowerOrEqualLiteral(column: String, literal: Literal)
  ColumnGreaterLiteral(column: String, literal: Literal)
  ColumnGreaterOrEqualLiteral(column: String, literal: Literal)
  ColumnNotEqualLiteral(column: String, literal: Literal)
  // Literal to Column comparison
  LiteralEqualColumn(literal: Literal, column: String)
  LiteralLowerColumn(literal: Literal, column: String)
  LiteralLowerOrEqualColumn(literal: Literal, column: String)
  LiteralGreaterColumn(literal: Literal, column: String)
  LiteralGreaterOrEqualColumn(literal: Literal, column: String)
  LiteralEqualNotColumn(literal: Literal, column: String)
  // Logical operators
  AndWhere(List(WhereFragment))
  NotWhere(List(WhereFragment))
  OrWhere(List(WhereFragment))
  // XorWhere(List(WhereFragment))
  // Column contains value
  ColumnInLiterals(column: String, literals: List(Literal))
}

pub type Null

pub type Literal {
  Bool(Bool)
  Float(Float)
  Int(Int)
  String(String)
  Null(Nil)
}

type Prepared =
  #(String, List(Literal))

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
pub fn to_prepared_sql(fragment frgmt: WhereFragment) -> Prepared {
  case frgmt {
    ColumnEqualColumn(a_col, b_col) -> #(a_col <> " = " <> b_col, [])
    ColumnLowerColumn(a_col, b_col) -> #(a_col <> " < " <> b_col, [])
    ColumnLowerOrEqualColumn(a_col, b_col) -> #(a_col <> " <= " <> b_col, [])
    ColumnGreaterColumn(a_col, b_col) -> #(a_col <> " > " <> b_col, [])
    ColumnGreaterOrEqualColumn(a_col, b_col) -> #(a_col <> " >= " <> b_col, [])
    ColumnNotEqualColumn(a_col, b_col) -> #(a_col <> " <> " <> b_col, [])
    ColumnEqualLiteral(col, Null(Nil)) -> #(col <> " IS NULL", [])
    ColumnEqualLiteral(col, lit) -> #(col <> " = ?", [lit])
    ColumnLowerLiteral(col, lit) -> #(col <> " < ?", [lit])
    ColumnLowerOrEqualLiteral(col, lit) -> #(col <> " <= ?", [lit])
    ColumnGreaterLiteral(col, lit) -> #(col <> " > ? ", [lit])
    ColumnGreaterOrEqualLiteral(col, lit) -> #(col <> " >= ? ", [lit])
    ColumnNotEqualLiteral(col, Null(Nil)) -> #(col <> " IS NOT NULL", [])
    ColumnNotEqualLiteral(col, lit) -> #(col <> " <> ? ", [lit])
    LiteralEqualColumn(Null(Nil), col) -> #(col <> "IS NULL", [])
    LiteralEqualColumn(lit, col) -> #("? = " <> col, [lit])
    LiteralLowerColumn(lit, col) -> #("? < " <> col, [lit])
    LiteralLowerOrEqualColumn(lit, col) -> #("? <= " <> col, [lit])
    LiteralGreaterColumn(lit, col) -> #("? > " <> col, [lit])
    LiteralGreaterOrEqualColumn(lit, col) -> #("? >= " <> col, [lit])
    LiteralEqualNotColumn(Null(Nil), col) -> #(col <> " IS NOT NULL", [])
    LiteralEqualNotColumn(lit, col) -> #("? <> " <> col, [lit])
    AndWhere(fragments) -> apply_logical_sql_operator(fragments, "AND")
    NotWhere(fragments) -> apply_logical_sql_operator(fragments, "NOT")
    OrWhere(fragments) -> apply_logical_sql_operator(fragments, "OR")
    ColumnInLiterals(col, lits) -> apply_column_in_literals(col, lits)
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
      let new_literals = list.append(acc.1, prepared.1)
      #(new_string, new_literals)
    },
  )
  |> pair.map_first(fn(string) { "(" <> string <> ")" })
}

fn apply_column_in_literals(col: String, lits: List(Literal)) -> Prepared {
  lits
  |> list.fold(#("", []), fn(acc: Prepared, lit: Literal) -> Prepared {
    let new_string = case acc.0 {
      "" -> "?"
      _ -> acc.0 <> ", ?"
    }
    let new_literals = list.append(acc.1, [lit])
    #(new_string, new_literals)
  })
  |> pair.map_first(fn(string) { col <> " IN (" <> string <> ")" })
}

pub fn to_sql(fragment frgmt: WhereFragment) -> String {
  frgmt
  |> to_prepared_sql()
  |> pair.first()
  // TODO: insert values here
}

// TODO: Move this to prepared statements and use question marks then,
// ... or at least optionally though.
fn lit_to_sql(literal: Literal) -> String {
  case literal {
    Bool(True) -> "TRUE"
    Bool(False) -> "FALSE"
    Float(value) -> float.to_string(value)
    Int(value) -> int.to_string(value)
    String(value) -> "'" <> value <> "'"
    Null(_) -> "NULL"
  }
}
