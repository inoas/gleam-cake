import gleam/dynamic
import test_support/adapter/postgres
import test_support/dummy

pub fn setup_and_run(query) {
  use conn <- postgres.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_owners_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_owners_rows() |> postgres.execute_raw_sql(conn)

  let _ = dummy.drop_cats_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_cats_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_cats_rows() |> postgres.execute_raw_sql(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_dogs_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_dogs_rows() |> postgres.execute_raw_sql(conn)
  // query |> postgres.run_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- postgres.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_owners_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_owners_rows() |> postgres.execute_raw_sql(conn)

  let _ = dummy.drop_cats_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_cats_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_cats_rows() |> postgres.execute_raw_sql(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = dummy.create_dogs_table() |> postgres.execute_raw_sql(conn)
  let _ = dummy.insert_dogs_rows() |> postgres.execute_raw_sql(conn)
  // query |> postgres.run_write(dynamic.dynamic, conn)
}
