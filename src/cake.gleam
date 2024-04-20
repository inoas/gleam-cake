import adapters/sqlite
import gleam/dynamic
import pprint
import query/select_query as sq
import sqlight

pub fn main() {
  let query =
    sq.new(select: ["name", "age"], from: "cats")
    |> sq.where(["age > 5"], True)

  use conn <- sqlight.with_connection(":memory:")

  let assert Ok(Nil) = create_dummy_cats_table(conn)
  let assert Ok(Nil) = insert_dummy_cats_data(conn)

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  sqlite.execute(conn, query, query_decoder)
  |> pprint.debug
}

fn create_dummy_cats_table(conn) {
  "CREATE TABLE cats (name text, age int);"
  |> sqlight.exec(conn)
}

fn insert_dummy_cats_data(conn) {
  "INSERT INTO cats (name, age) VALUES ('Nubi', 4), ('Biffy', 10), ('Ginny', 6);"
  |> sqlight.exec(conn)
}
