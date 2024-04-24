pub type SelectFragment {
  // Strings are arbitrary SQL strings
  // Aliases rename fields
  SelectString(string: String)
  SelectStringAlias(string: String, alias: String)
  // Columns are:
  // - auto prefixed? by their corresponding tables if not given
  // - checked if they exist
  SelectColumn(column: String)
  SelectColumnAlias(column: String, alias: String)
}

pub fn select_fragment_from_string(s: String) -> SelectFragment {
  // TODO: check if the table does indeed exist
  SelectString(s)
}

pub fn select_fragment_to_sql(fragment frgmt: SelectFragment) {
  case frgmt {
    SelectString(string) -> string
    SelectStringAlias(string, alias) -> string <> " AS " <> alias
    SelectColumn(column) -> column
    SelectColumnAlias(column, alias) -> column <> " AS " <> alias
  }
}
