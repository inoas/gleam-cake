import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/fragment/from_fragment
import cake/fragment/order_by_direction_fragment
import cake/fragment/select_fragment
import cake/fragment/where_fragment
import cake/param
import cake/query/select_query
import cake/stdlib/iox
import gleam/dynamic
import gleam/erlang/process

pub fn main() {
  iox.print_dashes()

  let where =
    where_fragment.OrWhere([
      where_fragment.WhereColEqualParam("age", param.IntParam(10)),
      where_fragment.WhereColEqualParam("name", param.StringParam("5")),
      where_fragment.WhereColInParams("age", [
        param.NullParam,
        param.IntParam(1),
        param.IntParam(2),
      ]),
    ])

  let query =
    select_query.select_query_new_from(from_fragment.from_fragment_from_table(
      "cats",
    ))
    |> select_query.select_query_select([
      select_fragment.select_fragment_from_string("name"),
      select_fragment.select_fragment_from_string("age"),
    ])
    |> select_query.select_query_set_where(where)
    |> select_query.select_query_order_asc("name")
    |> select_query.select_query_order_replace(
      by: "age",
      direction: order_by_direction_fragment.Asc,
    )
    |> select_query.select_query_set_limit(1)
    |> select_query.select_query_set_limit_and_offset(1, 0)
    |> iox.dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  iox.print_dashes()
  iox.print("Postgres: ")

  let _ =
    run_on_postgres(query, query_decoder)
    |> iox.dbg

  process.sleep(100)

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
