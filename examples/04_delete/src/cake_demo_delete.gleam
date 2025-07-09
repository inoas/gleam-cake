import cake/delete as d
import cake/insert as i
import cake/where as w
import gleam/dynamic
import gleam/io
import helper/adapter/postgres
import helper/demo_data

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
  use conn <- postgres.with_connection

  demo_data.create_tables_and_insert_rows(conn)

  let _insert_result =
    insert_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  let delete_result =
    delete_query() |> postgres.run_write_query(dynamic.dynamic, conn)

  echo delete_result
}
