import adapters/sqlite
import fragment/order_by_direction
import fragment/where
import gleam/dynamic
import pprint.{debug as dbg}
import query/select_query as sq
import sqlight

pub fn main() {
  let where_a = where.ColumnEqualLiteral("age", where.Int(10))
  let where_b = where.ColumnEqualLiteral("name", where.String("5"))
  let where_c =
    where.ColumnInLiterals("age", [where.String("-1"), where.Int(10)])
  let where = where.OrWhere([where_a, where_b, where_c])

  let where_string =
    where.ColumnNotEqualLiteral("name", where.Null(Nil))
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
