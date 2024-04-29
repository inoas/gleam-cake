import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/internal/query
import cake/param
import cake/stdlib/iox
import gleam/dynamic
import gleam/erlang/process

pub fn main() {
  run_dummy_select()
  run_dummy_union_all()

  Nil
}

pub fn run_dummy_select() {
  iox.print_dashes()

  let where =
    query.OrWhere([
      query.WhereColEqualParam("age", param.IntParam(10)),
      query.WhereColEqualParam("name", param.StringParam("5")),
      query.WhereColInParams("age", [
        param.NullParam,
        param.IntParam(1),
        param.IntParam(2),
      ]),
    ])

  let select_query =
    query.from_part_from_table("cats")
    |> query.select_query_new_from()
    |> query.select_query_select([
      query.select_part_from_string("name"),
      query.select_part_from_string("age"),
    ])
    |> query.select_query_set_where(where)
    |> query.select_query_order_asc("name")
    |> query.select_query_order_replace(by: "age", direction: query.Asc)
    |> query.select_query_set_limit(1)
    |> query.select_query_set_limit_and_offset(1, 0)
    |> query.query_select_wrap
    |> iox.dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  iox.print("SQLite: ")

  let _ =
    run_on_sqlite(select_query, query_decoder)
    |> iox.dbg

  process.sleep(100)

  iox.print("Postgres: ")

  let _ =
    run_on_postgres(select_query, query_decoder)
    |> iox.dbg

  process.sleep(100)
}

pub fn run_dummy_union_all() {
  iox.print_dashes()

  let select_query =
    query.from_part_from_table("cats")
    |> query.select_query_new_from()
    |> query.select_query_select([
      query.select_part_from_string("name"),
      query.select_part_from_string("age"),
    ])

  let select_query_a =
    select_query
    |> query.select_query_set_where(query.WhereColLowerOrEqualParam(
      "age",
      param.IntParam(4),
    ))
  let select_query_b =
    select_query
    |> query.select_query_set_where(query.WhereColGreaterOrEqualParam(
      "age",
      param.IntParam(7),
    ))

  // UNION must take ORDER BY at the outside
  // it can also take an own LIMIT and OFFSET
  // |> query.select_query_order_asc("name")

  let union_query =
    query.union_all_query_new([select_query_a, select_query_b])
    |> query.query_union_wrap
    |> iox.dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  iox.print("SQLite: ")

  let _ =
    run_on_sqlite(union_query, query_decoder)
    |> iox.dbg

  iox.print("Postgres: ")

  let _ =
    run_on_postgres(union_query, query_decoder)
    |> iox.dbg

  process.sleep(100)
}

pub fn run_on_postgres(query, query_decoder) {
  use conn <- postgres_adapter.with_connection()

  let _ = drop_cats_table_if_exists() |> postgres_adapter.execute(conn)

  let _ = create_cats_table() |> postgres_adapter.execute(conn)

  let _ = insert_cats_rows() |> postgres_adapter.execute(conn)

  postgres_adapter.run_query(conn, query, query_decoder)
}

fn run_on_sqlite(query, query_decoder) {
  use conn <- sqlite_adapter.with_memory_connection()

  let _ = drop_cats_table_if_exists() |> sqlite_adapter.execute(conn)

  let _ = create_cats_table() |> sqlite_adapter.execute(conn)

  let _ = insert_cats_rows() |> sqlite_adapter.execute(conn)

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
