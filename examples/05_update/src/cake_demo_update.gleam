import cake/adapter/postgres
import cake/update as u
import examples_helper/demo_data
import gleam/dynamic/decode
import gleam/option.{Some}

fn update_query() {
  u.new()
  |> u.table("cats")
  |> u.sets(["age" |> u.set_expression("age + 1"), "is_wild" |> u.set_true])
  |> u.returning(["name", "age", "is_wild"])
  |> u.to_query
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

  let result = update_query() |> postgres.run_write_query(decode.dynamic, conn)

  echo result
}
