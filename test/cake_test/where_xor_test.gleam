import birdie
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
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn where_xor_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.xor([
      w.col("name") |> w.eq(w.string("Karl")),
      w.col("is_wild") |> w.is_true,
      w.col("age") |> w.lte(w.int(9)),
    ]),
  )
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_xor_test() {
  where_xor_query()
  |> to_string
  |> birdie.snap("where_xor_test")
}

pub fn where_xor_prepared_statement_test() {
  let pgo = where_xor_query() |> postgres.read_query_to_prepared_statement
  let lit = where_xor_query() |> sqlite.read_query_to_prepared_statement
  let mdb = where_xor_query() |> maria.read_query_to_prepared_statement
  let myq = where_xor_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_prepared_statement_test")
}

pub fn where_xor_execution_result_test() {
  let pgo = where_xor_query() |> postgres_test_helper.setup_and_run
  let lit = where_xor_query() |> sqlite_test_helper.setup_and_run
  let mdb = where_xor_query() |> maria_test_helper.setup_and_run
  let myq = where_xor_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_execution_result_test")
}
