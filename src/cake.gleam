import cake/adapters/postgres_adapter
import cake/adapters/sqlite_adapter
import cake/fragment/order_by_direction
import cake/fragment/where as wf
import cake/query/select as sq
import cake/types
import gleam/dynamic
import gleam/io
import gleam/string
import pprint.{debug as dbg}

pub fn main() {
  print_dashes()
  io.println("Query")
  print_dashes()

  let where =
    wf.OrWhere([
      wf.ColEqualParam("age", types.IntParam(10)),
      wf.ColEqualParam("name", types.StringParam("5")),
      wf.ColInParams("age", [
        // types.StringParam("1"),
        types.IntParam(2),
        types.NullParam,
        types.IntParam(3),
      ]),
    ])

  let query =
    sq.new_from("cats")
    |> sq.select(["name, age"])
    |> sq.where_string("name NOT NULL")
    |> sq.where_replace([where])
    |> sq.order_asc("name")
    |> sq.order_replace(by: "age", direction: order_by_direction.Asc)
    |> sq.set_limit(1)
    |> sq.set_limit_and_offset(1, 0)
    |> dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  print_dashes()
  io.println("Running on SQLite")
  print_dashes()

  let _ =
    run_on_sqlite(query, query_decoder)
    |> dbg

  print_dashes()
  io.println("Running on Postgres")
  print_dashes()

  let _ =
    run_on_postgres(query, query_decoder)
    |> dbg

  Nil
}

fn run_on_sqlite(query, query_decoder) {
  use conn <- sqlite_adapter.with_memory_connection()

  let _ =
    create_dummy_cats_table()
    |> sqlite_adapter.execute(conn)

  let _ =
    insert_dummy_cats_data()
    |> sqlite_adapter.execute(conn)

  sqlite_adapter.run_query(conn, query, query_decoder)
}

fn run_on_postgres(query, query_decoder) {
  use conn <- postgres_adapter.with_memory_connection()

  let _ =
    create_dummy_cats_table()
    |> postgres_adapter.execute(conn)
  let _ =
    insert_dummy_cats_data()
    |> postgres_adapter.execute(conn)

  postgres_adapter.run_query(conn, query, query_decoder)
}

fn create_dummy_cats_table() {
  "CREATE TABLE cats (name text, age int);"
}

fn insert_dummy_cats_data() {
  "INSERT INTO cats (name, age) VALUES ('Nubi', 4), ('Biffy', 10), ('Ginny', 6);"
}

fn print_dashes() {
  io.println(string.repeat("—", 80))
}
//
// fn print_dashes_tap(tap) {
//   print_dashes()
//   tap
// }
