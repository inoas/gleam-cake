import gleam/dynamic/decode
import test_support/adapter/sqlite
import test_support/test_data

fn with_local_test_connection(callback callback) {
  sqlite.with_memory_connection(callback)
}

fn setup_database_default_values(conn) {
  let _ =
    test_data.drop_owners_table_if_exists() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> sqlite.execute_raw_sql(conn)

  let _ = test_data.drop_cats_table_if_exists() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> sqlite.execute_raw_sql(conn)

  let _ = test_data.drop_dogs_table_if_exists() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> sqlite.execute_raw_sql(conn)

  let _ =
    test_data.drop_counters_table_if_exists() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.create_counters_table() |> sqlite.execute_raw_sql(conn)
  let _ = test_data.insert_counters_rows() |> sqlite.execute_raw_sql(conn)
}

pub fn setup_and_run(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> sqlite.run_read_query(decode.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> sqlite.run_write_query(decode.dynamic, conn)
}

pub fn setup_and_run_write_value(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> sqlite.run_write_query(decode.dynamic, conn)
}
