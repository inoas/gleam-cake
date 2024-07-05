import demo_helper/postgres
import gleam/io
import pprint

pub fn create_tables_and_insert_rows(conn) {
  io.println("create_tables_and_insert_rows")

  drop_owners_table_if_exists()
  |> run_and_debug("drop_owners_table_if_exists", conn)

  create_owners_table()
  |> run_and_debug("create_owners_table", conn)

  insert_owners_rows()
  |> run_and_debug("insert_owners_rows", conn)

  drop_cats_table_if_exists()
  |> run_and_debug("drop_cats_table_if_exists", conn)

  create_cats_table()
  |> run_and_debug("create_cats_table", conn)

  insert_cats_rows()
  |> run_and_debug("insert_cats_rows", conn)

  drop_dogs_table_if_exists()
  |> run_and_debug("drop_dogs_table_if_exists", conn)

  create_dogs_table()
  |> run_and_debug("create_dogs_table", conn)

  insert_dogs_rows()
  |> run_and_debug("insert_dogs_rows", conn)

  Nil
}

fn drop_owners_table_if_exists() {
  "DROP TABLE IF EXISTS owners;"
}

fn create_owners_table() {
  "CREATE TABLE owners (
    id INT,
    name TEXT,
    last_name TEXT,
    age INT
  );"
}

fn insert_owners_rows() {
  "INSERT INTO owners (id, name, last_name, age) VALUES
    (1, 'Alice', 'Wibble', 5),
    (2, 'Bob', 'Wobble', 8),
    (3, 'Charlie', 'Wabble', 13)
  ;"
}

fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

fn create_cats_table() {
  "CREATE TABLE cats (
    name TEXT,
    age INT,
    is_wild BOOLEAN,
    owner_id INT,
    rating FLOAT(8)
  );"
}

fn insert_cats_rows() {
  "INSERT INTO cats (name, age, is_wild, owner_id, rating) VALUES
    ('Nubi', 4, TRUE, 1, 2.2),
    ('Biffy', 10, NULL, 2, 1.1),
    ('Ginny', 6, FALSE, 3, NULL),
    ('Karl', 8, TRUE, NULL, 10.0),
    ('Clara', 3, TRUE, NULL, 10.0)
  ;"
}

fn drop_dogs_table_if_exists() {
  "DROP TABLE IF EXISTS dogs;"
}

fn create_dogs_table() {
  "CREATE TABLE dogs (
    name TEXT,
    age INT,
    is_trained BOOLEAN,
    owner_id INT
  );"
}

fn insert_dogs_rows() {
  "INSERT INTO dogs (name, age, is_trained, owner_id) VALUES
    ('Fubi', 1, TRUE, 1),
    ('Diffy', 2, NULL, 2),
    ('Tinny', 3, FALSE, 3),
    ('Karl', 4, TRUE, NULL),
    ('Clara', 5, TRUE, NULL)
  ;"
}

fn run_and_debug(query, label, conn) {
  io.print(label <> ": ")

  let _ =
    query
    |> postgres.execute_raw_sql(conn)
    |> pprint.debug

  Nil
}
