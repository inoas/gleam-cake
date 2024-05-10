import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/internal/query as q
import cake/param as p
import cake/query/comparison.{EQ, GT, GTE, LT, LTE}
import cake/query/fragment as f
import cake/query/where as w
import cake/stdlib/iox
import gleam/dynamic
import gleam/erlang/process

pub fn main() {
  run_dummy_select()
  run_dummy_union_all()

  Nil
}

pub fn run_dummy_select() {
  iox.print_dashes()

  let cats_sub_query =
    q.from_part_from_table(table_name: "cats")
    |> q.select_query_new_from()

  let dogs_sub_query =
    q.from_part_from_table(table_name: "dogs")
    |> q.select_query_new_from()

  // let cats = column.Column("cats", _)

  let where =
    w.or([
      w.cond(w.col("cats.age"), EQ, w.int(10)),
      w.cond(w.col("cats.name"), EQ, w.string("foo")),
      w.in(w.col("cats.age"), [w.int(1), w.int(2)]),
    ])

  let select_query =
    cats_sub_query
    |> q.query_select_wrap()
    |> q.from_part_from_sub_query(alias: "cats")
    |> q.select_query_new_from()
    |> q.select_query_select([
      q.select_part_from("cats.name"),
      q.select_part_from("cats.age"),
      q.select_part_from("owners.name AS owner_name"),
    ])
    |> q.select_query_set_where(where)
    |> q.select_query_order_asc("cats.name")
    |> q.select_query_order_replace(by: "cats.age", direction: q.Asc)
    |> q.select_query_set_limit(1)
    |> q.select_query_set_limit_and_offset(1, 0)
    |> q.select_query_set_join([
      q.InnerJoin(
        with: q.JoinTable("owners"),
        alias: "owners",
        on: w.or([
          w.eq(w.col("owners.id"), w.col("cats.owner_id")),
          w.lt(w.col("owners.id"), w.int(20)),
          w.is_not_null(w.col("owners.id")),
          w.eq(
            w.fragment(f.literal("LOWER(owners.name)")),
            w.fragment(f.prepared(
              "LOWER(" <> f.placeholder <> ")",
              p.string("Timmy"),
            )),
          ),
        ]),
      ),
      q.CrossJoin(
        with: q.JoinSubQuery(q.query_select_wrap(dogs_sub_query)),
        alias: "dogs",
      ),
    ])
    |> q.query_select_wrap
    |> iox.dbg

  process.sleep(100)

  let query_decoder =
    dynamic.tuple3(dynamic.string, dynamic.int, dynamic.string)

  iox.println("SQLite")

  let _ =
    run_on_sqlite(select_query, query_decoder)
    |> iox.print_tap("Result: ")
    |> iox.dbg

  process.sleep(100)

  iox.println("Postgres")

  let _ =
    run_on_postgres(select_query, query_decoder)
    |> iox.print_tap("Result: ")
    |> iox.dbg

  process.sleep(100)
}

pub fn run_dummy_union_all() {
  iox.print_dashes()

  let select_query =
    q.from_part_from_table("cats")
    |> q.select_query_new_from()
    |> q.select_query_select([
      q.select_part_from("name"),
      q.select_part_from("age"),
    ])

  let select_query_a =
    select_query
    |> q.select_query_set_where(
      w.or([
        w.lte(w.col("age"), w.int(4)),
        w.like(w.col("name"), "%ara%"),
        // q.WhereColSimilarTo("name", "%(y|a)%"), // NOTICE: Does not run on Sqlite
      ]),
    )

  let where_b =
    q.NotWhere(q.WhereIsNotBool(w.col("is_wild"), False))
    |> iox.dbg_label("where_b")

  let select_query_b =
    select_query
    |> q.select_query_set_where(q.WhereGreaterOrEqual(w.col("age"), w.int(7)))
    |> q.select_query_order_asc(by: "will_be_removed")
    |> q.select_query_set_where(where_b)

  let union_query =
    q.combined_union_all_query_new([select_query_a, select_query_b])
    |> q.combined_query_set_limit(1)
    |> q.combined_query_order_replace(by: "age", direction: q.Asc)
    |> q.query_combined_wrap
    |> iox.dbg

  let query_decoder = dynamic.tuple2(dynamic.string, dynamic.int)

  process.sleep(100)

  iox.println("SQLite")

  let _ =
    run_on_sqlite(union_query, query_decoder)
    |> iox.print_tap("Result: ")
    |> iox.dbg

  process.sleep(100)

  iox.println("Postgres")

  let _ =
    run_on_postgres(union_query, query_decoder)
    |> iox.print_tap("Result: ")
    |> iox.dbg

  process.sleep(100)
}

pub fn run_on_postgres(query, query_decoder) {
  use conn <- postgres_adapter.with_connection()

  let _ = drop_owners_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = create_owners_table() |> postgres_adapter.execute(conn)
  let _ = insert_owners_rows() |> postgres_adapter.execute(conn)

  let _ = drop_cats_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = create_cats_table() |> postgres_adapter.execute(conn)
  let _ = insert_cats_rows() |> postgres_adapter.execute(conn)

  let _ = drop_dogs_table_if_exists() |> postgres_adapter.execute(conn)
  let _ = create_dogs_table() |> postgres_adapter.execute(conn)
  let _ = insert_dogs_rows() |> postgres_adapter.execute(conn)

  postgres_adapter.run_query(conn, query, query_decoder)
}

fn run_on_sqlite(query, query_decoder) {
  use conn <- sqlite_adapter.with_memory_connection()

  let _ = drop_owners_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = create_owners_table() |> sqlite_adapter.execute(conn)
  let _ = insert_owners_rows() |> sqlite_adapter.execute(conn)

  let _ = drop_cats_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = create_cats_table() |> sqlite_adapter.execute(conn)
  let _ = insert_cats_rows() |> sqlite_adapter.execute(conn)

  let _ = drop_dogs_table_if_exists() |> sqlite_adapter.execute(conn)
  let _ = create_dogs_table() |> sqlite_adapter.execute(conn)
  let _ = insert_dogs_rows() |> sqlite_adapter.execute(conn)

  sqlite_adapter.run_query(conn, query, query_decoder)
}

fn drop_owners_table_if_exists() {
  "DROP TABLE IF EXISTS owners;"
}

fn create_owners_table() {
  "CREATE TABLE owners (
    id int,
    name text,
    last_name text,
    age int,
    tags text[]
  );"
}

fn insert_owners_rows() {
  "INSERT INTO owners (id, name, last_name, age) VALUES
    (1, 'Alice', 'Foo', 5),
    (2, 'bob', 'BOB', 8),
    (3, 'Charlie', 'Quux', 13)
  ;"
}

fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

fn create_cats_table() {
  "CREATE TABLE cats (
    name text,
    age int,
    is_wild boolean,
    owner_id int
  );"
}

fn insert_cats_rows() {
  "INSERT INTO cats (name, age, is_wild, owner_id) VALUES
    ('Nubi', 4, TRUE, 1),
    ('Biffy', 10, NULL, 2),
    ('Ginny', 6, FALSE, 3),
    ('Karl', 8, TRUE, NULL),
    ('Clara', 3, TRUE, NULL)
  ;"
}

fn drop_dogs_table_if_exists() {
  "DROP TABLE IF EXISTS dogs;"
}

fn create_dogs_table() {
  "CREATE TABLE dogs (
    name text,
    age int,
    is_trained boolean,
    owner_id int
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
