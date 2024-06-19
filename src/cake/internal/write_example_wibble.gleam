// TODO v1: Move this into snapshot tests
import cake/internal/query.{NoComment}
import cake/internal/write_query.{
  type InsertRow, type WriteQuery, Insert, InsertColumns, InsertConflictError,
  InsertIntoTable, InsertParam, InsertRow, InsertSourceParams, NoInsertModifier,
  NoReturning,
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

pub fn insert_to_write_query(wibbles: List(Wibble)) -> WriteQuery(Wibble) {
  wibbles
  |> InsertSourceParams(caster: caster)
  |> Insert(
    into_table: InsertIntoTable(table_name),
    modifier: NoInsertModifier,
    columns: InsertColumns(columns),
    on_conflict: InsertConflictError,
    returning: NoReturning,
    comment: NoComment,
  )
  |> write_query.insert_to_write_query
}

pub fn update_to_write_query(wibbles: List(Wibble)) -> WriteQuery(Wibble) {
  todo
}

pub fn delete_to_write_query(wibbles: List(Wibble)) -> WriteQuery(Wibble) {
  todo
}
