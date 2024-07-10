import gleam/dynamic
import test_support/adapter/postgres
import test_support/test_data

pub fn setup_and_run(query) {
  use conn <- postgres.with_connection

  let _ =
    test_data.drop_owners_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> postgres.execute_raw_sql(conn)

  let _ =
    test_data.drop_cats_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> postgres.execute_raw_sql(conn)

  let _ =
    test_data.drop_dogs_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> postgres.execute_raw_sql(conn)

  query |> postgres.run_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- postgres.with_connection

  let _ =
    test_data.drop_owners_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> postgres.execute_raw_sql(conn)

  let _ =
    test_data.drop_cats_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> postgres.execute_raw_sql(conn)

  let _ =
    test_data.drop_dogs_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> postgres.execute_raw_sql(conn)

  let _ =
    test_data.drop_counters_table_if_exists() |> postgres.execute_raw_sql(conn)
  let _ = test_data.create_counters_table() |> postgres.execute_raw_sql(conn)
  let _ = test_data.insert_counters_rows() |> postgres.execute_raw_sql(conn)

  query |> postgres.run_write(dynamic.dynamic, conn)
}
