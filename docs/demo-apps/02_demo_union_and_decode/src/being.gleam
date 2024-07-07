import gleam/dynamic.{decode2, element, from, int, string}

pub type Being {
  Being(name: String, age: Int)
}

pub fn from_postgres(row) {
  // NOTICE: This\ will crash, if the returned data from the SQL query does not match
  let assert Ok(couple) =
    row
    |> from
    |> decode2(Being, element(0, string), element(1, int))

  couple
}
