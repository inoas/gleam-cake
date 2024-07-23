import cake/update as u
import gleam/dynamic
import gleam/io
import helper/demo_data
import helper/postgres
import pprint

fn update_query() {
  u.new()
  |> u.table("cats")
  |> u.sets(["age" |> u.set_expression("age + 1"), "is_wild" |> u.set_true])
  |> u.returning(["name", "age", "is_wild"])
  |> u.to_query
}

pub fn main() {
  use conn <- postgres.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  // NOTICE: This will crash, if the SQL query fails.
  let result = update_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  io.println("Result: ")

  result
  |> pprint.debug
}
