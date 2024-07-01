import birdie
import cake/fragment as frgmt
import cake/select as s
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

const const_field = "age"

fn select_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([
    s.col("name"),
    // s.bool(True),
    // s.float(1.0),
    // s.int(1),
    s.string("hello"),
    s.fragment(frgmt.literal(const_field)),
    s.alias(s.col("age"), "years_since_birth"),
  ])
  |> s.to_query
}

pub fn select_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_test")
}

pub fn select_prepared_statement_test() {
  let pgo = select_query() |> postgres.to_prepared_statement
  let lit = select_query() |> sqlite.to_prepared_statement
  let mdb = select_query() |> maria.to_prepared_statement
  let myq = select_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_prepared_statement_test")
}

pub fn select_execution_result_test() {
  let pgo = select_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_query() |> maria_test_helper.setup_and_run
  let myq = select_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_execution_result_test")
}

fn select_distinct_query() {
  s.new()
  |> s.from_table("cats")
  |> s.distinct
  |> s.selects([s.col("is_wild")])
  |> s.order_by_asc("is_wild")
  |> s.to_query
}

pub fn select_distinct_test() {
  select_distinct_query()
  |> to_string
  |> birdie.snap("select_distinct_test")
}

pub fn select_distinct_prepared_statement_test() {
  let pgo = select_distinct_query() |> postgres.to_prepared_statement
  let lit = select_distinct_query() |> sqlite.to_prepared_statement
  let mdb = select_distinct_query() |> maria.to_prepared_statement
  let myq = select_distinct_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_distinct_prepared_statement_test")
}

pub fn select_distinct_execution_result_test() {
  let pgo = select_distinct_query() |> postgres_test_helper.setup_and_run
  let lit = select_distinct_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_distinct_query() |> maria_test_helper.setup_and_run
  let myq = select_distinct_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_distinct_execution_result_test")
}
