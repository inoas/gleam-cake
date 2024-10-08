import birdie
import cake/delete as d
import cake/fragment as f
import cake/join as j
import cake/select as s
import cake/where as w
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

fn delete() {
  d.new()
  |> d.table("owners")
  |> d.where(w.col("owners.name") |> w.eq(w.string("Alice")))
}

fn delete_postgres() {
  delete()
  |> d.using_table("cats")
  |> d.where(w.col("cats.owner_id") |> w.eq(w.col("owners.id")))
  |> d.join(j.inner(
    with: j.table("dogs"),
    on: w.col("dogs.name") |> w.eq(w.col("cats.name")),
    alias: "dogs",
  ))
  |> d.returning(["owners.id"])
}

fn delete_sqlite() {
  delete()
  |> d.returning(["owners.id"])
}

fn delete_maria_mysql() {
  delete()
  |> d.using_table("owners")
  |> d.using_table("cats")
  |> d.where(w.col("cats.owner_id") |> w.eq(w.col("owners.id")))
  |> d.join(j.inner(
    with: j.table("dogs"),
    on: w.col("dogs.name") |> w.eq(w.col("cats.name")),
    alias: "dogs",
  ))
}

// 🦭MariaDB and 🐬MYSQL do not support RETURNING or do not support it
// reliably.
//
const affected_row_count_frgmt = "ROW_COUNT()"

fn delete_affected_row_count_maria_mysql_query() {
  s.new()
  |> s.select(s.fragment(f.literal(affected_row_count_frgmt)))
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn delete_test() {
  let pgo = delete_postgres() |> d.to_query
  let lit = delete_sqlite() |> d.to_query
  let mdb = delete_maria_mysql() |> d.to_query
  let myq = mdb

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("delete_test")
}

pub fn delete_prepared_statement_test() {
  let pgo =
    delete_postgres()
    |> d.to_query
    |> postgres.write_query_to_prepared_statement
  let lit =
    delete_sqlite() |> d.to_query |> sqlite.write_query_to_prepared_statement
  let mdb =
    delete_maria_mysql()
    |> d.to_query
    |> maria.write_query_to_prepared_statement
  let myq =
    delete_maria_mysql()
    |> d.to_query
    |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("delete_prepared_statement_test")
}

pub fn delete_execution_result_test() {
  let pgo =
    delete_postgres()
    |> d.to_query
    |> postgres_test_helper.setup_and_run_write
  let lit =
    delete_sqlite() |> d.to_query |> sqlite_test_helper.setup_and_run_write
  let mdb_exec =
    delete_maria_mysql()
    |> d.to_query
    |> maria_test_helper.setup_and_run_write
  let mdb_cnt =
    delete_affected_row_count_maria_mysql_query()
    |> maria_test_helper.setup_and_run
  let myq_exec =
    delete_maria_mysql()
    |> d.to_query
    |> mysql_test_helper.setup_and_run_write
  let myq_cnt =
    delete_affected_row_count_maria_mysql_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, #(mdb_exec, mdb_cnt), #(myq_exec, myq_cnt))
  |> to_string
  |> birdie.snap("delete_execution_result_test")
}
