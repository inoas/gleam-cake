import birdie
import cake/query/insert as i
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

type Cat {
  Cat(name: String, age: Int, is_wild: Bool, rating: Float)
}

fn cat_caster(cat: Cat) {
  [
    i.param(column: "name", param: cat.name |> i.string),
    i.param(column: "rating", param: cat.rating |> i.float),
    i.param(column: "age", param: cat.age |> i.int),
    // i.param(column: "owner_id", param: i.null()), i.param(column: "is_wild", param: cat.is_wild |> i.bool),
  ]
  |> i.row
}

fn insert_records() {
  let cats = [
    Cat(name: "Whiskers", age: 3, is_wild: False, rating: 5.0),
    Cat(name: "Mittens", age: 5, is_wild: True, rating: 4.5),
  ]

  i.from_records(
    table_name: "cats",
    columns: [
      "name", "rating", "age",
      // "owner_id", "is_wild"
    ],
    records: cats,
    caster: cat_caster,
  )
  |> i.returning(["name"])
}

fn insert_records_query() {
  insert_records()
  |> i.to_query
}

fn insert_records_maria_mysql_query() {
  insert_records()
  |> i.no_returning
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_records_test() {
  let pgo = insert_records_query()
  let lit = pgo
  let mdb = insert_records_maria_mysql_query()
  let myq = mdb

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_records_test")
}

pub fn insert_records_prepared_statement_test() {
  let pgo = insert_records_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_records_query() |> sqlite.write_query_to_prepared_statement
  let mdb =
    insert_records_maria_mysql_query()
    |> maria.write_query_to_prepared_statement
  let myq =
    insert_records_maria_mysql_query()
    |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_records_prepared_statement_test")
}

pub fn insert_records_execution_result_test() {
  let pgo = insert_records_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_records_query() |> sqlite_test_helper.setup_and_run_write
  let mdb =
    insert_records_maria_mysql_query() |> maria_test_helper.setup_and_run_write
  let myq =
    insert_records_maria_mysql_query() |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_records_execution_result_test")
}
