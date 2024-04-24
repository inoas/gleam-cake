import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/fragment/from as ff
import cake/fragment/order_by_direction
import cake/fragment/where as wf
import cake/query/select as sq
import cake/stdlib/iox
import cake/types
import gleam/dynamic
import gleam/erlang/process as erlang_process

pub fn main() {
  iox.print_dashes()

  let where =
    wf.OrWhere([
      wf.ColEqualParam("age", types.IntParam(10)),
      wf.ColEqualParam("name", types.StringParam("5")),
      wf.ColInParams("age", [
        types.NullParam,
        types.IntParam(1),
        types.IntParam(2),
      ]),
    ])

  let query =
    sq.new_from(ff.FromFragment("cats"))
    |> sq.select(["name, age"])
    |> sq.set_where(where)
    |> sq.order_asc("name")
    |> sq.order_replace(by: "age", direction: order_by_direction.Asc)
    |> sq.set_limit(1)
    |> sq.set_limit_and_offset(1, 0)
    |> iox.dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  iox.print_dashes()
  iox.print("Postgres: ")

  let _ =
    run_on_postgres(query, query_decoder)
    |> iox.dbg

  erlang_process.sleep(100)

  iox.print_dashes()
  iox.print("SQLite:   ")

  let _ =
    run_on_sqlite(query, query_decoder)
    |> iox.dbg

  Nil
}

fn run_on_postgres(query, query_decoder) {
  // iox.println("run_on_postgres")

  use conn <- postgres_adapter.with_connection()

  let _ =
    drop_cats_table_if_exists()
    |> postgres_adapter.execute(conn)
  // |> iox.dbg_label("drop_cats_table_if_exists")

  let _ =
    create_cats_table()
    |> postgres_adapter.execute(conn)
  // |> iox.dbg_label("create_cats_table")

  let _ =
    insert_cats_rows()
    |> postgres_adapter.execute(conn)
  // |> iox.dbg_label("insert_cats_rows")

  postgres_adapter.run_query(conn, query, query_decoder)
}

fn run_on_sqlite(query, query_decoder) {
  // iox.println("run_on_sqlite")

  use conn <- sqlite_adapter.with_memory_connection()

  let _ =
    drop_cats_table_if_exists()
    |> sqlite_adapter.execute(conn)
  // |> iox.dbg_label("drop_cats_table_if_exists")

  let _ =
    create_cats_table()
    |> sqlite_adapter.execute(conn)
  // |> iox.dbg_label("create_cats_table")

  let _ =
    insert_cats_rows()
    |> sqlite_adapter.execute(conn)
  // |> iox.dbg_label("insert_cats_rows")

  sqlite_adapter.run_query(conn, query, query_decoder)
}

fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

fn create_cats_table() {
  "CREATE TABLE cats (name text, age int);"
}

fn insert_cats_rows() {
  "INSERT INTO cats (name, age) VALUES ('Nubi', 4), ('Biffy', 10), ('Ginny', 6);"
}
