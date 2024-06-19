import cake/adapter/postgres
import gleam/dynamic
import support/dummy

pub fn setup_and_run(query) {
  use conn <- postgres.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_owners_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_owners_rows() |> postgres.raw_execute(conn)

  let _ = dummy.drop_cats_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_cats_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_cats_rows() |> postgres.raw_execute(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_dogs_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_dogs_rows() |> postgres.raw_execute(conn)

  query |> postgres.run_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- postgres.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_owners_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_owners_rows() |> postgres.raw_execute(conn)

  let _ = dummy.drop_cats_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_cats_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_cats_rows() |> postgres.raw_execute(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> postgres.raw_execute(conn)
  let _ = dummy.create_dogs_table() |> postgres.raw_execute(conn)
  let _ = dummy.insert_dogs_rows() |> postgres.raw_execute(conn)

  query |> postgres.run_write(dynamic.dynamic, conn)
}
