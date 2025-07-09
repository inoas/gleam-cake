import gleam/dynamic/decode
import gleam/erlang/process
import gleam/option.{Some}
import test_support/adapter/postgres
import test_support/test_data

const process_name = "postgres_demo"

fn with_local_test_connection(callback callback) {
  let process = process.new_name(process_name)

  postgres.with_connection(
    process:,
    host: "localhost",
    port: 5432,
    username: "postgres",
    password: Some("postgres"),
    database: "gleam_cake_test",
    callback:,
  )
}

fn setup_database_default_values(conn) {
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
}

pub fn setup_and_run(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> postgres.run_read_query(decode.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- with_local_test_connection

  let _ = setup_database_default_values(conn)

  query |> postgres.run_write_query(decode.dynamic, conn)
}
