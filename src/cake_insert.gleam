//// This module exists for premature testing only
//// It will be removed or replaced shortly before v1

import cake/adapter/postgres
import cake/adapter/sqlite
import cake/internal/stdlib/iox
import cake/internal/write_example_wibble
import cake/internal/write_query.{type WriteQuery}
import gleam/dynamic
import gleam/erlang/process

pub fn main() {
  process.sleep(100)

  let _ = exec_dummy_insert()

  process.sleep(100)

  Nil
}

pub fn exec_dummy_insert() {
  iox.print_dashes()

  let query_decoder = dynamic.dynamic

  iox.println("SQLite")

  let _ =
    run_write_on_sqlite(
      [write_example_wibble.new()] |> write_example_wibble.to_write_query(),
      query_decoder,
    )
    |> iox.print_tap("Result: ")
    |> iox.dbg

  process.sleep(100)

  iox.println("Postgres")

  let _ =
    run_write_on_postgres(
      [
        write_example_wibble.new(),
        write_example_wibble.new(),
        write_example_wibble.new(),
      ]
        |> write_example_wibble.to_write_query(),
      query_decoder,
    )
    |> iox.print_tap("Result: ")
    |> iox.dbg
}

fn run_write_on_postgres(query: WriteQuery(t), query_decoder) {
  use conn <- postgres.with_connection
  let _ = drop_cats_table_if_exists() |> postgres.raw_execute(conn)
  let _ = create_cats_table() |> postgres.raw_execute(conn)
  query |> postgres.run_write(query_decoder, conn)
}

fn run_write_on_sqlite(query: WriteQuery(t), query_decoder) {
  use conn <- sqlite.with_memory_connection
  let _ = drop_cats_table_if_exists() |> sqlite.raw_execute(conn)
  let _ = create_cats_table() |> sqlite.raw_execute(conn)
  query |> sqlite.run_write(query_decoder, conn)
}

fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

fn create_cats_table() {
  "CREATE TABLE cats (
    name text,
    age int,
    is_wild boolean,
    owner_id int
  );"
}
