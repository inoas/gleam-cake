import cake/adapter/postgres
import cake/fragment as f
import cake/select as s
import cake/where as w
import examples_helper/demo_data
import gleam/dynamic/decode
import gleam/option.{Some}

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
  use conn <- postgres.with_connection(
    host: "localhost",
    port: 5432,
    username: "postgres",
    password: Some("postgres"),
    database: "gleam_cake_examples",
  )

  demo_data.create_tables_and_insert_rows(conn)

  let rows = fragment_query() |> postgres.run_read_query(decode.dynamic, conn)

  echo rows
}
