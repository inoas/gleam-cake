import cake/join as j
import cake/select as s
import cake/where as w
import cat
import examples_helper/adapter/postgres
import examples_helper/demo_data
import gleam/dynamic
import gleam/io
import gleam/list

fn select_query() {
  s.new()
  |> s.selects([
    s.col("cats.name"),
    s.col("cats.age"),
    s.col("cats.is_wild"),
    s.col("owners.name"),
  ])
  |> s.from_table("cats")
  |> s.join(j.inner(
    with: j.table("owners"),
    on: w.col("owners.id") |> w.eq(w.col("cats.owner_id")),
    alias: "owners",
  ))
  |> s.where(w.col("owners.name") |> w.like("%li%"))
  |> s.order_by_asc("cats.name")
  |> s.limit(3)
  |> s.offset(0)
  |> s.epilog("FOR UPDATE")
  |> s.comment("Gets up to 3 cats with their age and owner's name!")
  |> s.to_query
}

pub fn main() {
  use conn <- postgres.with_connection
  demo_data.create_tables_and_insert_rows(conn)

  let assert Ok(rows) =
    select_query() |> postgres.run_read_query(dynamic.dynamic, conn)

  echo rows

  //  See `cat.gleam` for an example how to decode rows.
  let decoded_cats = rows |> list.map(cat.from_postgres)

  echo decoded_cats
}
