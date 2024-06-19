import birdie
import cake/adapter/postgres
import cake/adapter/sqlite
import cake/query/insert as i
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

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

fn insert_custom_type_query() {
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
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_custom_type_test() {
  insert_custom_type_query()
  |> to_string
  |> birdie.snap("insert_custom_type_test")
}

pub fn insert_custom_type_prepared_statement_test() {
  let pgo =
    insert_custom_type_query() |> postgres.write_query_to_prepared_statement
  let lit =
    insert_custom_type_query() |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_custom_type_prepared_statement_test")
}

pub fn insert_custom_type_execution_result_test() {
  let pgo =
    insert_custom_type_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_custom_type_query() |> sqlite_test_helper.setup_and_run_write

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_custom_type_execution_result_test")
}
