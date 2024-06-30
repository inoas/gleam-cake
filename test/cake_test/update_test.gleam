import birdie
import cake/query/fragment as f
import cake/query/select as s
import cake/query/update as u
import gleam/string
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

fn update() {
  let swap_bool_exp_sql =
    "(CASE WHEN is_Wild IS true THEN false ELSE true END) AS swapped_is_wild"
    |> string.trim()

  let sub_query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.fragment(f.literal(swap_bool_exp_sql)))
    |> s.limit(1)
    |> s.to_query

  u.new(table: "cats", sets: [
    "age" |> u.set_to_expression("age + 1"),
    "name" |> u.set_to_param(u.string("Joe")),
    "is_wild" |> u.set_to_sub_query(sub_query),
  ])
  |> u.returning(["name", "age"])
}

fn update_query() {
  update()
  |> u.to_query
}

fn update_maria_mysql_query() {
  // MariaDB/MySQL do not support `RETURNING` in `UPDATE` queries:
  update()
  |> u.no_returning
  |> u.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn update_test() {
  let pgo = update_query()
  let lit = pgo
  let mdb = update_maria_mysql_query()
  let myq = mdb

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_test")
}

pub fn update_prepared_statement_test() {
  let pgo = update_query() |> postgres.write_query_to_prepared_statement
  let lit = update_query() |> sqlite.write_query_to_prepared_statement
  let mdb =
    update_maria_mysql_query() |> maria.write_query_to_prepared_statement
  let myq =
    update_maria_mysql_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_prepared_statement_test")
}

pub fn update_execution_result_test() {
  let pgo = update_query() |> postgres_test_helper.setup_and_run_write
  let lit = update_query() |> sqlite_test_helper.setup_and_run_write
  let mdb = update_maria_mysql_query() |> maria_test_helper.setup_and_run_write
  let myq = update_maria_mysql_query() |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_execution_result_test")
}
