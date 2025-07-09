import cake/insert as i
import examples_helper/adapter/postgres
import examples_helper/demo_data
import gleam/dynamic

fn insert_query() {
  [
    [i.string("Whiskers"), i.int(1)] |> i.row,
    [i.string("Karl"), i.int(2)] |> i.row,
    [i.string("Clara"), i.int(3)] |> i.row,
  ]
  |> i.from_values(table_name: "cats", columns: ["name", "age"])
  |> i.returning(["name", "age"])
  |> i.to_query
}

pub fn main() {
  use conn <- postgres.with_connection

  demo_data.create_tables_and_insert_rows(conn)

  let result = insert_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  echo result

  Nil
}
