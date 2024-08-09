import birdie
import cake/fragment as f
import cake/select as s
import cake/update as u
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

fn swap_is_wild_sub_query() {
  let swap_bool_sql_exp =
    "(CASE WHEN is_Wild IS true THEN false ELSE true END) AS swapped_is_wild"

  s.new()
  |> s.from_table("cats")
  |> s.select(s.fragment(f.literal(swap_bool_sql_exp)))
  |> s.limit(1)
  |> s.to_query
}

fn update_postgres_sqlite_query() {
  u.new()
  |> u.table("cats")
  |> u.sets([
    "age" |> u.set_expression("age + 1"),
    "name" |> u.set_string("Joe"),
    "is_wild" |> u.set_sub_query(swap_is_wild_sub_query()),
  ])
  |> u.returning(["name", "age"])
  |> u.to_query
}

fn update_maria_query() {
  u.new()
  |> u.table("cats")
  |> u.sets([
    "age" |> u.set_expression("age + 1"),
    "name" |> u.set_string("Joe"),
    "is_wild" |> u.set_sub_query(swap_is_wild_sub_query()),
  ])
  // 🦭MariaDB does not support `RETURNING` in `UPDATE` queries:
  // |> u.returning(["name", "age"])
  |> u.to_query
}

fn update_mysql_query() {
  u.new()
  |> u.table("cats")
  |> u.sets([
    "age" |> u.set_expression("age + 1"),
    "name" |> u.set_string("Joe"),
    // "is_wild" |> u.set_sub_query(swap_is_wild_sub_query()), // 🐬MySQL fails to execute this query
  ])
  // 🐬MySQL do not support `RETURNING` in `UPDATE` queries:
  // |> u.returning(["name", "age"])
  |> u.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn update_test() {
  let pgo = update_postgres_sqlite_query()
  let lit = pgo
  let mdb = update_maria_query()
  let myq = update_mysql_query()

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_test")
}

pub fn update_prepared_statement_test() {
  let pgo =
    update_postgres_sqlite_query() |> postgres.write_query_to_prepared_statement
  let lit =
    update_postgres_sqlite_query() |> sqlite.write_query_to_prepared_statement
  let mdb = update_maria_query() |> maria.write_query_to_prepared_statement
  let myq = update_mysql_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_prepared_statement_test")
}

pub fn update_execution_result_test() {
  let pgo =
    update_postgres_sqlite_query() |> postgres_test_helper.setup_and_run_write
  let lit =
    update_postgres_sqlite_query() |> sqlite_test_helper.setup_and_run_write
  let mdb = update_maria_query() |> maria_test_helper.setup_and_run_write
  let myq = update_mysql_query() |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_execution_result_test")
}
