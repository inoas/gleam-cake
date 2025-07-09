import cake/fragment as f
import cake/select as s
import cake/where as w
import examples_helper/adapter/postgres
import examples_helper/demo_data
import gleam/dynamic
import gleam/io

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
  use conn <- postgres.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  let rows = fragment_query() |> postgres.run_read_query(dynamic.dynamic, conn)

  echo rows
}
