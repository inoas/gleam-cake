import being
import cake/adapter/postgres
import cake/combined as c
import cake/select as s
import gleam/dynamic
import gleam/io
import gleam/list
import helper/demo_data
import pprint

fn union_query() {
  let owners_query =
    s.new()
    |> s.select(s.col("CONCAT('Owner ', owners.name), age"))
    |> s.from_table("owners")

  let cats_query =
    s.new()
    |> s.select(s.col("CONCAT('Cat ', cats.name), age"))
    |> s.from_table("cats")

  owners_query
  |> c.union(cats_query)
  |> c.to_query
}

pub fn main() {
  use conn <- postgres.with_connection

  demo_data.create_tables_and_insert_rows(conn)

  let assert Ok(rows) =
    union_query() |> postgres.run_read_query(dynamic.dynamic, conn)

  echo rows

  //  See `being.gleam` for an example how to decode rows.
  let decoded_beings = rows |> list.map(being.from_postgres)

  echo decoded_beings
}
