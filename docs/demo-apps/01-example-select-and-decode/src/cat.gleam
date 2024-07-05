import gleam/dynamic.{bool, decode4, element, from, int, string}

pub type Cat {
  Cat(name: String, age: Int, is_wild: Bool, owners_name: String)
}

pub fn from_postgres(row) {
  // NOTICE: This will crash, if the returned data from the SQL query does not match
  let assert Ok(cat) =
    row
    |> from
    |> decode4(
      Cat,
      element(0, string),
      element(1, int),
      element(2, bool),
      element(3, string),
    )

  cat
}
