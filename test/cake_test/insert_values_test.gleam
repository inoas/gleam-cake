import birdie
import cake/insert as i
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

fn insert_values() {
  [[i.string("Whiskers"), i.float(3.14), i.int(42)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "rating", "age"])
  |> i.returning(["name"])
}

fn insert_values_query() {
  insert_values()
  |> i.to_query
}

fn insert_values_maria_mysql_query() {
  // 🦭MariaDB and 🐬MySQL do not support `RETURNING` in `INSERT` queries:
  insert_values()
  |> i.no_returning
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_values_test() {
  let pgo = insert_values_query()
  let lit = pgo
  let mdb = insert_values_maria_mysql_query()
  let myq = mdb

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_test")
}

pub fn insert_values_prepared_statement_test() {
  let pgo = insert_values_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_values_query() |> sqlite.write_query_to_prepared_statement
  let mdb =
    insert_values_maria_mysql_query() |> maria.write_query_to_prepared_statement
  let myq =
    insert_values_maria_mysql_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_prepared_statement_test")
}

pub fn insert_values_execution_result_test() {
  let pgo = insert_values_query() |> postgres_test_helper.setup_and_run_write
  let lit = insert_values_query() |> sqlite_test_helper.setup_and_run_write
  let mdb =
    insert_values_maria_mysql_query() |> maria_test_helper.setup_and_run_write
  let myq =
    insert_values_maria_mysql_query() |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_execution_result_test")
}
