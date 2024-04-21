import gleam/float
import gleam/int
import gleam/list
import gleam/string

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

// TODO: Move this to prepared statements and use question marks then
// ... or at least optionally though.
pub fn to_sql(fragment frgmt: WhereFragment) -> String {
  case frgmt {
    ColumnEqualColumn(a_col, b_col) -> a_col <> " = " <> b_col
    ColumnLowerColumn(a_col, b_col) -> a_col <> " < " <> b_col
    ColumnLowerOrEqualColumn(a_col, b_col) -> a_col <> " <= " <> b_col
    ColumnGreaterColumn(a_col, b_col) -> a_col <> " > " <> b_col
    ColumnGreaterOrEqualColumn(a_col, b_col) -> a_col <> " >= " <> b_col
    ColumnNotEqualColumn(a_col, b_col) -> a_col <> " <> " <> b_col
    ColumnEqualLiteral(col, Null(Nil)) -> col <> " IS NULL"
    ColumnEqualLiteral(col, lit) -> col <> " = " <> literal_to_sql(lit)
    ColumnLowerLiteral(col, lit) -> col <> " < " <> literal_to_sql(lit)
    ColumnLowerOrEqualLiteral(col, lit) -> col <> " <= " <> literal_to_sql(lit)
    ColumnGreaterLiteral(col, lit) -> col <> " > " <> literal_to_sql(lit)
    ColumnGreaterOrEqualLiteral(col, lit) ->
      col <> " >= " <> literal_to_sql(lit)
    ColumnNotEqualLiteral(col, Null(Nil)) -> col <> " IS NOT NULL"
    ColumnNotEqualLiteral(col, lit) -> col <> " <> " <> literal_to_sql(lit)
    LiteralEqualColumn(Null(Nil), col) -> col <> " IS NULL"
    LiteralEqualColumn(lit, col) -> literal_to_sql(lit) <> " = " <> col
    LiteralLowerColumn(lit, col) -> literal_to_sql(lit) <> " < " <> col
    LiteralLowerOrEqualColumn(lit, col) -> literal_to_sql(lit) <> " <= " <> col
    LiteralGreaterColumn(lit, col) -> literal_to_sql(lit) <> " > " <> col
    LiteralGreaterOrEqualColumn(lit, col) ->
      literal_to_sql(lit) <> " >= " <> col
    LiteralEqualNotColumn(Null(Nil), col) -> col <> " IS NOT NULL"
    LiteralEqualNotColumn(lit, col) -> literal_to_sql(lit) <> " <> " <> col
    AndWhere(fragments) ->
      "("
      <> list.map(fragments, to_sql)
      |> string.join(" AND ")
      <> ")"
    NotWhere(fragments) ->
      "("
      <> list.map(fragments, to_sql)
      |> string.join(" NOT ")
      <> ")"
    OrWhere(fragments) ->
      "("
      <> list.map(fragments, to_sql)
      |> string.join(" OR ")
      <> ")"
    ColumnInLiterals(col, lits) ->
      col
      <> " IN ("
      <> list.map(lits, literal_to_sql)
      |> string.join(", ")
      <> ")"
  }
}

// TODO: Move this to prepared statements and use question marks then,
// ... or at least optionally though.
fn literal_to_sql(literal: Literal) -> String {
  case literal {
    Bool(True) -> "TRUE"
    Bool(False) -> "FALSE"
    Float(value) -> float.to_string(value)
    Int(value) -> int.to_string(value)
    String(value) -> "'" <> value <> "'"
    Null(_) -> "NULL"
  }
}
