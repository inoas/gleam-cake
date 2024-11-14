import cake/adapter/postgres
import cake/delete as d
import cake/insert as i
import cake/where as w
import gleam/dynamic
import gleam/io
import helper/demo_data
import helper/postgres_helper
import pprint

fn insert_query() {
  [[i.string("Deletee"), i.int(1)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "age"])
  |> i.returning(["name", "age"])
  |> i.to_query
}

fn delete_query() {
  d.new()
  |> d.table("cats")
  |> d.where(w.col("cats.name") |> w.eq(w.string("Deletee")))
  |> d.returning(["name", "age"])
  |> d.to_query
}

pub fn main() {
  use conn <- postgres_helper.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  let insert_result =
    insert_query() |> postgres.run_write_query(dynamic.dynamic, conn)
  let delete_result =
    delete_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  io.println("Results: ")

  #("Inserted:", insert_result, "Deleted:", delete_result)
  |> pprint.debug
}
