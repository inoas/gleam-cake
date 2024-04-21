import adapters/sqlite
import fragment/order_by_direction
import gleam/dynamic
import pprint
import query/select_query as sq
import sqlight

pub fn main() {
  let query =
    sq.new_from("cats")
    |> sq.select(["name AS foo", "age AS bar"])
    |> sq.where(["age > 5"])
    |> sq.order_asc("name")
    |> sq.order_replace(by: "age", direction: order_by_direction.Asc)
    |> sq.set_limit(-1)
    |> sq.set_limit_and_offset(1, 1)

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
