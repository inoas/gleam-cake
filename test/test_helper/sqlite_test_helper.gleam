import cake/adapter/sqlite_adapter
import gleam/dynamic
import support/dummy

pub fn setup_and_run(query) {
  use conn <- sqlite_adapter.with_memory_connection

  let _ = dummy.drop_owners_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = dummy.create_owners_table() |> sqlite_adapter.execute(conn)
  let _ = dummy.insert_owners_rows() |> sqlite_adapter.execute(conn)

  let _ = dummy.drop_cats_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = dummy.create_cats_table() |> sqlite_adapter.execute(conn)
  let _ = dummy.insert_cats_rows() |> sqlite_adapter.execute(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = dummy.create_dogs_table() |> sqlite_adapter.execute(conn)
  let _ = dummy.insert_dogs_rows() |> sqlite_adapter.execute(conn)

  sqlite_adapter.run_query(conn, query, dynamic.dynamic)
}
