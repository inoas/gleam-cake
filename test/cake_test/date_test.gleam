import birdie
import cake/select as s
import cake/where as w
import gleam/time/calendar
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

fn date_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([
    s.alias(s.col("birthday"), "kids_birthday"),
    s.alias(s.date(calendar.Date(2016, calendar.February, 19)), "kbirthday"),
  ])
  |> s.where(
    w.col("birthday")
    |> w.eq(w.date(calendar.Date(2016, calendar.February, 19))),
  )
  |> s.or_where(
    w.col("birthday")
    |> w.between(
      w.date(calendar.Date(2021, calendar.April, 12)),
      w.date(calendar.Date(2021, calendar.April, 14)),
    ),
  )
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn date_test() {
  date_query()
  |> to_string
  |> birdie.snap("date_test")
}

pub fn date_prepared_statement_test() {
  let pgo = date_query() |> postgres.read_query_to_prepared_statement
  let lit = date_query() |> sqlite.read_query_to_prepared_statement
  let mdb = date_query() |> maria.read_query_to_prepared_statement
  let myq = date_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("date_prepared_statement_test")
}

pub fn date_execution_result_test() {
  let pgo = date_query() |> postgres_test_helper.setup_and_run
  let lit = date_query() |> sqlite_test_helper.setup_and_run
  let mdb = date_query() |> maria_test_helper.setup_and_run
  let myq = date_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("date_execution_result_test")
}
