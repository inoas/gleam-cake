import birdie
import cake/query/insert as i
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

type Cat {
  Cat(name: String, age: Int, is_wild: Bool)
}

fn cat_caster(cat cat: Cat) {
  [
    i.param(column: "name", param: cat.name |> i.string),
    i.param(column: "age", param: cat.age |> i.int),
    i.param(column: "is_wild", param: cat.is_wild |> i.bool),
  ]
  |> i.row
}

fn insert_records_query() {
  let cats = [
    Cat(name: "Whiskers", age: 3, is_wild: False),
    Cat(name: "Mittens", age: 5, is_wild: True),
  ]

  i.from_records(
    table_name: "cats",
    columns: ["name", "age", "is_wild"],
    records: cats,
    caster: cat_caster,
  )
  |> i.returning(["name"])
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_records_test() {
  insert_records_query()
  |> to_string
  |> birdie.snap("insert_records_test")
}

pub fn insert_records_prepared_statement_test() {
  let pgo = insert_records_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_records_query() |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_records_prepared_statement_test")
}

pub fn insert_records_execution_result_test() {
  let pgo = insert_records_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_records_query() |> sqlite_test_helper.setup_and_run_write

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_records_execution_result_test")
}
