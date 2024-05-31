import cake/adapter/postgres_adapter
import gleam/dynamic
import support/dummy

pub fn setup_and_run(query) {
  use conn <- postgres_adapter.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = dummy.create_owners_table() |> postgres_adapter.execute(conn)
  let _ = dummy.insert_owners_rows() |> postgres_adapter.execute(conn)

  let _ = dummy.drop_cats_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = dummy.create_cats_table() |> postgres_adapter.execute(conn)
  let _ = dummy.insert_cats_rows() |> postgres_adapter.execute(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = dummy.create_dogs_table() |> postgres_adapter.execute(conn)
  let _ = dummy.insert_dogs_rows() |> postgres_adapter.execute(conn)

  postgres_adapter.run_query(conn, query, dynamic.dynamic)
}
