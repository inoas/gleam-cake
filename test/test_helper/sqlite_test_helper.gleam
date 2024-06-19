import cake/adapter/sqlite
import gleam/dynamic
import support/dummy

pub fn setup_and_run(query) {
  use conn <- sqlite.with_memory_connection

  let _ = dummy.drop_owners_table_if_exists() |> sqlite.execute(conn)
  let _ = dummy.create_owners_table() |> sqlite.execute(conn)
  let _ = dummy.insert_owners_rows() |> sqlite.execute(conn)

  let _ = dummy.drop_cats_table_if_exists() |> sqlite.execute(conn)
  let _ = dummy.create_cats_table() |> sqlite.execute(conn)
  let _ = dummy.insert_cats_rows() |> sqlite.execute(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> sqlite.execute(conn)
  let _ = dummy.create_dogs_table() |> sqlite.execute(conn)
  let _ = dummy.insert_dogs_rows() |> sqlite.execute(conn)

  sqlite.run_query(conn, query, dynamic.dynamic)
}
