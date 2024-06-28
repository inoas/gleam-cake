import gleam/dynamic
import test_support/adapter/mysql
import test_support/dummy

pub fn setup_and_run(query) {
  use conn <- mysql.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_owners_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_owners_rows() |> mysql.execute_raw_sql(conn)

  let _ = dummy.drop_cats_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_cats_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_cats_rows() |> mysql.execute_raw_sql(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_dogs_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_dogs_rows() |> mysql.execute_raw_sql(conn)

  query |> mysql.run_query(dynamic.dynamic, conn)
}

pub fn setup_and_run_write(query) {
  use conn <- mysql.with_connection

  let _ = dummy.drop_owners_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_owners_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_owners_rows() |> mysql.execute_raw_sql(conn)

  let _ = dummy.drop_cats_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_cats_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_cats_rows() |> mysql.execute_raw_sql(conn)

  let _ = dummy.drop_dogs_table_if_exists() |> mysql.execute_raw_sql(conn)
  let _ = dummy.create_dogs_table() |> mysql.execute_raw_sql(conn)
  let _ = dummy.insert_dogs_rows() |> mysql.execute_raw_sql(conn)

  query |> mysql.run_write(dynamic.dynamic, conn)
}
