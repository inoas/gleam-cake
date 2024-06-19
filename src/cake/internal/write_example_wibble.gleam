import cake/internal/write_query.{
  type InsertRow, type WriteQuery, Insert, InsertParam, InsertRow,
}
import cake/param

pub const table_name = "cats"

pub const columns = ["name", "age", "is_wild"]

pub type Wibble {
  Wibble(name: String, age: Int, is_wild: Bool)
}

pub fn new() {
  Wibble(name: "Wibble", age: 42, is_wild: True)
}

fn caster(wibble: Wibble) -> InsertRow {
  let Wibble(name: name, age: age, is_wild: is_wild) = wibble

  InsertRow(row: [
    InsertParam(column: "name", param: name |> param.string),
    InsertParam(column: "age", param: age |> param.int),
    InsertParam(column: "is_wild", param: is_wild |> param.bool),
  ])
}

pub fn to_write_query(wibbles: List(Wibble)) -> WriteQuery(Wibble) {
  wibbles
  |> Insert(into: table_name, columns: columns, caster: caster)
  |> write_query.to_write_query
}
