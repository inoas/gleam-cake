import cake/adapter/postgres
import cake/fragment as f
import cake/select as s
import cake/where as w
import gleam/dynamic
import gleam/io
import helper/demo_data
import helper/postgres_helper
import pprint

fn fragment_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.fragment_value(f.literal("LOWER(cats.name)"))
    |> w.eq(
      w.fragment_value(
        f.prepared("LOWER(" <> f.placeholder <> ")", [f.string("cLaRa")]),
      ),
    ),
  )
  |> s.to_query
}

pub fn main() {
  use conn <- postgres_helper.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  let result =
    fragment_query() |> postgres.run_read_query(dynamic.dynamic, conn)

  io.println("Result: ")

  result
  |> pprint.debug
}
