import cake/insert as i
import cake/update as u
import cake/where as w
import helper/demo_data
import helper/postgres
import gleam/dynamic
import gleam/io
import pprint

fn update() {
  u.new() |> u.sets(["counter" |> u.set_expression("counters.counter + 1")])
}

fn insert_query() {
  [
    [i.string("Whiskers"), i.int(1)] |> i.row,
    [i.string("Karl"), i.int(1)] |> i.row,
    [i.string("Clara"), i.int(1)] |> i.row,
  ]
  |> i.from_values(table_name: "counters", columns: ["name", "counter"])
  |> i.on_columns_conflict_update(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
    update: update(),
  )
  |> i.returning(["name", "counter"])
  |> i.to_query
}

pub fn main() {
  use conn <- postgres.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  // NOTICE: This will crash, if the SQL query fails.
  let result = insert_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  io.println("Result: ")

  result
  |> pprint.debug
}
