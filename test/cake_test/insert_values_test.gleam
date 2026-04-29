import birdie
import cake/fragment as f
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

pub fn insert_values_fragment_test() {
  let pgo_lit_query =
    [
      [
        i.fragment(
          f.prepared("$::uuid", [
            f.string("000000000-0000-4000-a000-a00000000000"),
          ]),
        ),
        i.string("Alice"),
        i.int(42),
      ]
      |> i.row,
    ]
    |> i.from_values(table_name: "users", columns: ["id", "name", "age"])
    |> i.returning(["id", "name"])
    |> i.to_query

  let mdb_myq_query =
    [
      [
        i.fragment(
          f.prepared("$", [f.string("000000000-0000-4000-a000-a00000000000")]),
        ),
        i.string("Alice"),
        i.int(42),
      ]
      |> i.row,
    ]
    |> i.from_values(table_name: "users", columns: ["id", "name", "age"])
    // MariaDB and MySQL do not support `RETURNING` in `INSERT` queries:
    |> i.no_returning
    |> i.to_query

  let pgo = pgo_lit_query |> postgres.write_query_to_prepared_statement
  let lit = pgo_lit_query |> sqlite.write_query_to_prepared_statement
  let mdb = mdb_myq_query |> maria.write_query_to_prepared_statement
  let myq = mdb_myq_query |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_fragment_test")
}

pub fn insert_values_multi_fragment_test() {
  let pgo_lit_query =
    [
      [
        i.fragment(f.prepared("LOWER($)", [f.string("FELIX")])),
        i.fragment(f.prepared("$", [f.int(2)])),
      ]
      |> i.row,
    ]
    |> i.from_values(table_name: "cats", columns: ["name", "age"])
    |> i.returning(["name", "age"])
    |> i.to_query

  let mdb_myq_query =
    [
      [
        i.fragment(f.prepared("LOWER($)", [f.string("FELIX")])),
        i.fragment(f.prepared("$", [f.int(2)])),
      ]
      |> i.row,
    ]
    |> i.from_values(table_name: "cats", columns: ["name", "age"])
    // MariaDB and MySQL do not support `RETURNING` in `INSERT` queries:
    |> i.no_returning
    |> i.to_query

  let pgo = pgo_lit_query |> postgres.write_query_to_prepared_statement
  let lit = pgo_lit_query |> sqlite.write_query_to_prepared_statement
  let mdb = mdb_myq_query |> maria.write_query_to_prepared_statement
  let myq = mdb_myq_query |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_multi_fragment_test")
}

fn insert_values_fragment_cats_pgo_lit_query() {
  [[i.fragment(f.prepared("LOWER($)", [f.string("FELIX")])), i.int(2)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "age"])
  |> i.returning(["name", "age"])
  |> i.to_query
}

fn insert_values_fragment_cats_mdb_myq_query() {
  [[i.fragment(f.prepared("LOWER($)", [f.string("FELIX")])), i.int(2)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "age"])
  // MariaDB and MySQL do not support `RETURNING` in `INSERT` queries:
  |> i.no_returning
  |> i.to_query
}

pub fn insert_values_fragment_execution_result_test() {
  let pgo =
    insert_values_fragment_cats_pgo_lit_query()
    |> postgres_test_helper.setup_and_run_write
  let lit =
    insert_values_fragment_cats_pgo_lit_query()
    |> sqlite_test_helper.setup_and_run_write
  let mdb =
    insert_values_fragment_cats_mdb_myq_query()
    |> maria_test_helper.setup_and_run_write
  let myq =
    insert_values_fragment_cats_mdb_myq_query()
    |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_values_fragment_execution_result_test")
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
