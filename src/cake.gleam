import cake/adapters/sqlite
import cake/fragment/order_by_direction
import cake/fragment/where
import cake/query/select as sq
import gleam/dynamic
import pprint.{debug as dbg}
import sqlight

pub fn main() {
  let where_a = where.ColEqualParam("age", where.IntParam(10))
  let where_b = where.ColEqualParam("name", where.StringParam("5"))
  let where_c =
    where.ColInParams("age", [where.StringParam("-1"), where.IntParam(10)])
  let where = where.OrWhere([where_a, where_b, where_c])

  let where_string =
    where.ColNotEqualParam("name", where.NullParam)
    |> where.to_sql

  let query =
    sq.new_from("cats")
    |> sq.select(["name", "age"])
    |> sq.where_strings([where_string])
    |> sq.where([where])
    |> sq.order_asc("name")
    |> sq.order_replace(by: "age", direction: order_by_direction.Asc)
    |> sq.set_limit(-1)
    |> sq.set_limit_and_offset(10, 0)
    |> dbg

  use conn <- sqlight.with_connection(":memory:")

  let assert Ok(Nil) = create_dummy_cats_table(conn)
  let assert Ok(Nil) = insert_dummy_cats_data(conn)

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  sqlite.execute(conn, query, query_decoder)
  |> dbg
}

fn create_dummy_cats_table(conn) {
  "CREATE TABLE cats (name text, age int);"
  |> sqlight.exec(conn)
}

fn insert_dummy_cats_data(conn) {
  "INSERT INTO cats (name, age) VALUES ('Nubi', 4), ('Biffy', 10), ('Ginny', 6);"
  |> sqlight.exec(conn)
}
