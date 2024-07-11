import gleam/dynamic
import test_support/adapter/sqlite
import test_support/test_data

pub fn setup_and_run(query) {
  use conn <- sqlite.with_memory_connection

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

  query |> sqlite.run_read_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- sqlite.with_memory_connection

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

  query |> sqlite.run_write_query(dynamic.dynamic, conn)
}
