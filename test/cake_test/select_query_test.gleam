import birdie
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

pub fn select_query_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("cats.name"))
  |> s.join(j.cross(with: j.table("owners"), alias: "owners"))
  |> s.where(w.col("owners.name") |> w.like("%i%"))
  |> s.group_by("cats.name")
  |> s.having(w.col("cats.name") |> w.like("%i%"))
  |> s.order_by_asc("cats.name")
  |> s.limit(10)
  |> s.offset(1)
  |> s.epilog("/* an epilog such as FOR UPDATE could be here */")
  |> s.comment("my regular comment /* */")
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_query_test() {
  select_query_query()
  |> to_string
  |> birdie.snap("select_query_test")
}

pub fn select_query_prepared_statement_test() {
  let pgo = select_query_query() |> postgres.read_query_to_prepared_statement
  let lit = select_query_query() |> sqlite.read_query_to_prepared_statement
  let mdb = select_query_query() |> maria.read_query_to_prepared_statement
  let myq = select_query_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_query_prepared_statement_test")
}

pub fn select_query_execution_result_test() {
  let pgo = select_query_query() |> postgres_test_helper.setup_and_run
  let lit = select_query_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_query_query() |> maria_test_helper.setup_and_run
  let myq = select_query_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_query_execution_result_test")
}
