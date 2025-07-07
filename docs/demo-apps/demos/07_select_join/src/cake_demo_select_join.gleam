import cake/adapter/postgres
import cake/join as j
import cake/select as s
import cake/where as w
import gleam/dynamic
import gleam/io
import helper/demo_data

fn select_join_query() {
  s.new()
  |> s.selects([s.col("owners.name"), s.col("dogs.name")])
  |> s.from_table("owners")
  |> s.join(j.left(
    with: j.table("dogs"),
    on: w.col("owners.id") |> w.eq(w.col("dogs.owner_id")),
    alias: "dogs",
  ))
  |> s.to_query
}

pub fn main() {
  use conn <- postgres.with_connection

  demo_data.create_tables_and_insert_rows(conn)

  let rows =
    select_join_query() |> postgres.run_read_query(dynamic.dynamic, conn)

  echo rows
}
