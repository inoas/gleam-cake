import birdie
import cake/adapter/postgres
import cake/adapter/sqlite
import cake/internal/query.{NoComment}
import cake/internal/write_query.{
  type InsertRow, type WriteQuery, Insert, InsertColumns, InsertConflictError,
  InsertIntoTable, InsertParam, InsertRow, InsertSourceParams, NoInsertModifier,
  Returning,
}
import cake/param
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

const table_name = "cats"

const columns = ["name", "age", "is_wild"]

type Cat {
  Cat(name: String, age: Int, is_wild: Bool)
}

fn caster(cat: Cat) -> InsertRow {
  let Cat(name: name, age: age, is_wild: is_wild) = cat
  InsertRow(row: [
    InsertParam(column: "name", param: name |> param.string),
    InsertParam(column: "age", param: age |> param.int),
    InsertParam(column: "is_wild", param: is_wild |> param.bool),
  ])
}

fn insert_query() -> WriteQuery(Cat) {
  let cats = [
    Cat(name: "Whiskers", age: 3, is_wild: False),
    Cat(name: "Mittens", age: 5, is_wild: True),
  ]
  Insert(
    into_table: InsertIntoTable(table: table_name),
    modifier: NoInsertModifier,
    source: InsertSourceParams(records: cats, caster: caster),
    columns: InsertColumns(cols: columns),
    on_conflict: InsertConflictError,
    returning: Returning(["name"]),
    comment: NoComment,
  )
  |> write_query.to_insert_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_test() {
  insert_query()
  |> to_string
  |> birdie.snap("insert_test")
}

pub fn insert_prepared_statement_test() {
  let pgo = insert_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_query() |> sqlite.write_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_prepared_statement_test")
}

pub fn insert_execution_result_test() {
  let pgo = insert_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_query() |> sqlite_test_helper.setup_and_run_write

  #(pgo, lit)
  |> to_string
  |> birdie.snap("insert_execution_result_test")
}
