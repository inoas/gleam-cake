import gleam/dynamic/decode

pub type Being {
  Being(name: String, age: Int)
}

pub fn from_postgres(row) {
  let decoder = {
    use name <- decode.field(0, decode.string)
    use age <- decode.field(1, decode.int)
    Being(name:, age:) |> decode.success()
  }

  // NOTICE: This will crash, if the returned data from the SQL query does not match
  //
  let assert Ok(being) = decode.run(row, decoder)

  being
}
