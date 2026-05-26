import birdie
import cake/select as s
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn select_for_update_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("name"), s.col("age")])
  |> s.epilog("FOR UPDATE")
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_epilog_test() {
  select_for_update_query()
  |> to_string
  |> birdie.snap("select_epilog_test")
}

pub fn select_epilog_prepared_statement_test() {
  let pgo =
    select_for_update_query() |> postgres.read_query_to_prepared_statement
  let mdb = select_for_update_query() |> maria.read_query_to_prepared_statement
  let myq = select_for_update_query() |> mysql.read_query_to_prepared_statement

  #(pgo, mdb, myq)
  |> to_string
  |> birdie.snap("select_epilog_prepared_statement_test")
}

pub fn select_epilog_execution_result_test() {
  let pgo = select_for_update_query() |> postgres_test_helper.setup_and_run
  let mdb = select_for_update_query() |> maria_test_helper.setup_and_run
  let myq = select_for_update_query() |> mysql_test_helper.setup_and_run

  #(pgo, mdb, myq)
  |> to_string
  |> birdie.snap("select_epilog_execution_result_test")
}
