import gleam/dynamic
import test_support/adapter/mysql
import test_support/test_data

pub fn setup_and_run(query) {
  use conn <- mysql.with_connection

  let _ = test_data.drop_owners_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> mysql.execute_raw_sql(conn)

  let _ = test_data.drop_cats_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> mysql.execute_raw_sql(conn)

  let _ = test_data.drop_dogs_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> mysql.execute_raw_sql(conn)

  query |> mysql.run_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- mysql.with_connection

  let _ = test_data.drop_owners_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_owners_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_owners_rows() |> mysql.execute_raw_sql(conn)

  let _ = test_data.drop_cats_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_cats_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_cats_rows() |> mysql.execute_raw_sql(conn)

  let _ = test_data.drop_dogs_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = test_data.create_dogs_table() |> mysql.execute_raw_sql(conn)
  let _ = test_data.insert_dogs_rows() |> mysql.execute_raw_sql(conn)

  query |> mysql.run_write(dynamic.dynamic, conn)
}
