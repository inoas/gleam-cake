import gleam/dynamic/decode
import gleam/option.{Some}
import test_support/adapter/maria
import test_support/test_data

fn with_local_test_connection(callback callback) {
  maria.with_connection(
    host: "localhost",
    port: 3307,
    username: Some("root"),
    password: "",
    database: "gleam_cake_test",
    callback:,
  )
}

fn setup_database_default_values(conn) {
  let _ = test_data.drop_owners_table_if_exists() |> maria.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> maria.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> maria.execute_raw_sql(conn)

  let _ = test_data.drop_cats_table_if_exists() |> maria.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> maria.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> maria.execute_raw_sql(conn)

  let _ = test_data.drop_dogs_table_if_exists() |> maria.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> maria.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> maria.execute_raw_sql(conn)

  let _ =
    test_data.drop_counters_table_if_exists() |> maria.execute_raw_sql(conn)
  let _ = test_data.create_counters_table() |> maria.execute_raw_sql(conn)
  let _ = test_data.insert_counters_rows() |> maria.execute_raw_sql(conn)
}

pub fn setup_and_run(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> maria.run_read_query(decode.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> maria.run_write_query(decode.dynamic, conn)
}
