import gleam/dynamic/decode

pub type Cat {
  Cat(name: String, age: Int, is_wild: Bool, owners_name: String)
}

pub fn from_postgres(row) -> Cat {
  let decoder = {
    use name <- decode.field(0, decode.string)
    use age <- decode.field(1, decode.int)
    use is_wild <- decode.field(2, decode.bool)
    use owners_name <- decode.field(3, decode.string)
    Cat(name:, age:, is_wild:, owners_name:) |> decode.success()
  }

  // NOTICE: This will crash, if the returned data from the SQL query does not match
  //
  let assert Ok(cat) = decode.run(row, decoder)

  cat
}
