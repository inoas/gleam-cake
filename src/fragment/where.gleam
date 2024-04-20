pub type WhereFragment {
  // Column A to B comparison
  ColumnAEqualColumnB(column_a: String, column_b: String)
  ColumnALowerThanColumnB(column_a: String, column_b: String)
  ColumnALowerThanOrEqualColumnB(column_a: String, column_b: String)
  ColumnAGreaterThanColumnB(column_a: String, column_b: String)
  ColumnAGreaterThanOrEqualColumnB(column_a: String, column_b: String)
  // Column A to Value comparison
  ColumnAEqualValue(column_a: String, value: Literal)
  ColumnALowerThanValue(column_a: String, value: Literal)
  ColumnALowerThanOrEqualValue(column_a: String, value: Literal)
  ColumnAGreaterThanValue(column_a: String, value: Literal)
  ColumnAGreaterThanOrEqualValue(column_a: String, value: Literal)
  // Value to Column B comparison
  ValueEqualColumnB(value: Literal, column_b: String)
  ValueLowerThanColumnB(value: Literal, column_b: String)
  ValueLowerThanOrEqualColumnB(value: Literal, column_b: String)
  ValueGreaterThanColumnB(value: Literal, column_b: String)
  ValueGreaterThanOrEqualColumnB(value: Literal, column_b: String)
  // Contains
  In(List(String))
  // Logical operators
  AndWhere(List(WhereFragment))
  NotWhere(List(WhereFragment))
  OrWhere(List(WhereFragment))
  XorWhere(List(WhereFragment))
}

pub type SqlNull

pub type Literal {
  Bool(Bool)
  Float(Float)
  Int(Int)
  SqlNull(SqlNull)
  String(String)
}
