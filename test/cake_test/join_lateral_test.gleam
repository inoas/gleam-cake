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

fn owners_query() {
  s.new()
  |> s.from_table("owners")
  |> s.select(s.col("owners.name"))
  |> s.where(w.col("owners.id") |> w.eq(w.col("cats.owner_id")))
  |> s.to_query
}

fn inner_join_lateral_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("cats.name"))
  |> s.join(j.inner_lateral(alias: "owners", with: j.sub_query(owners_query())))
  |> s.to_query
}

fn left_join_lateral_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("cats.name"))
  |> s.join(j.left_lateral(alias: "owners", with: j.sub_query(owners_query())))
  |> s.to_query
}

fn cross_join_lateral_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("cats.name"))
  |> s.join(j.cross_lateral(alias: "owners", with: j.sub_query(owners_query())))
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

// INNER JOIN LATERAL

pub fn inner_join_lateral_test() {
  inner_join_lateral_query()
  |> to_string
  |> birdie.snap("inner_join_lateral_test")
}

pub fn inner_join_lateral_prepared_statement_test() {
  let pgo =
    inner_join_lateral_query() |> postgres.read_query_to_prepared_statement
  let lit =
    inner_join_lateral_query() |> sqlite.read_query_to_prepared_statement
  let mdb = inner_join_lateral_query() |> maria.read_query_to_prepared_statement
  let myq = inner_join_lateral_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("inner_join_lateral_prepared_statement_test")
}

pub fn inner_join_lateral_execution_result_test() {
  let pgo = inner_join_lateral_query() |> postgres_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🪶SQlite does not support LATERAL JOINs.
  let lit = inner_join_lateral_query() |> sqlite_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🦭MariaDB does not support LATERAL JOINs.
  let mdb = inner_join_lateral_query() |> maria_test_helper.setup_and_run
  let myq = inner_join_lateral_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("inner_join_lateral_execution_result_test")
}

// LEFT JOIN LATERAL

pub fn left_join_lateral_test() {
  left_join_lateral_query()
  |> to_string
  |> birdie.snap("left_join_lateral_test")
}

pub fn left_join_lateral_prepared_statement_test() {
  let pgo =
    left_join_lateral_query() |> postgres.read_query_to_prepared_statement
  let lit = left_join_lateral_query() |> sqlite.read_query_to_prepared_statement
  let mdb = left_join_lateral_query() |> maria.read_query_to_prepared_statement
  let myq = left_join_lateral_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("left_join_lateral_prepared_statement_test")
}

pub fn left_join_lateral_execution_result_test() {
  let pgo = left_join_lateral_query() |> postgres_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🪶SQlite does not support LATERAL JOINs.
  let lit = left_join_lateral_query() |> sqlite_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🦭MariaDB does not support LATERAL JOINs.
  let mdb = left_join_lateral_query() |> maria_test_helper.setup_and_run
  let myq = left_join_lateral_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("left_join_lateral_execution_result_test")
}

// CROSS JOIN LATERAL

pub fn cross_join_lateral_test() {
  cross_join_lateral_query()
  |> to_string
  |> birdie.snap("cross_join_lateral_test")
}

pub fn cross_join_lateral_prepared_statement_test() {
  let pgo =
    cross_join_lateral_query() |> postgres.read_query_to_prepared_statement
  let lit =
    cross_join_lateral_query() |> sqlite.read_query_to_prepared_statement
  let mdb = cross_join_lateral_query() |> maria.read_query_to_prepared_statement
  let myq = cross_join_lateral_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("cross_join_lateral_prepared_statement_test")
}

pub fn cross_join_lateral_execution_result_test() {
  let pgo = cross_join_lateral_query() |> postgres_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🪶SQlite does not support LATERAL JOINs.
  let lit = cross_join_lateral_query() |> sqlite_test_helper.setup_and_run
  // NOTICE: This crashes as long as 🦭MariaDB does not support LATERAL JOINs.
  let mdb = cross_join_lateral_query() |> maria_test_helper.setup_and_run
  let myq = cross_join_lateral_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("cross_join_lateral_execution_result_test")
}
