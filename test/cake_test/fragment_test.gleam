import birdie
import cake/fragment as frgmt
import cake/internal/param as p
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

fn fragment_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.fragment_value(frgmt.literal("LOWER(cats.name)"))
    |> w.eq(
      w.fragment_value(
        frgmt.prepared("LOWER(" <> frgmt.placeholder <> ")", [p.string("Clara")]),
      ),
    ),
  )
  |> s.to_query
}

pub fn fragment_test() {
  fragment_query()
  |> to_string
  |> birdie.snap("fragment_test")
}

pub fn fragment_prepared_statement_test() {
  let pgo = fragment_query() |> postgres.to_prepared_statement
  let lit = fragment_query() |> sqlite.to_prepared_statement
  let mdb = fragment_query() |> maria.to_prepared_statement
  let myq = fragment_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("fragment_prepared_statement_test")
}

pub fn fragment_execution_result_test() {
  let pgo = fragment_query() |> postgres_test_helper.setup_and_run
  let lit = fragment_query() |> sqlite_test_helper.setup_and_run
  let mdb = fragment_query() |> maria_test_helper.setup_and_run
  let myq = fragment_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("fragment_execution_result_test")
}
