import birdie
import cake/query/combined as c
import cake/query/select as s
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

fn query() {
  s.new()
  |> s.from_table("cats")
  |> s.order_by_asc("name")
  |> s.limit(10)
  |> s.offset(0)
}

fn combined_union_all_query() {
  let query = query()

  query
  |> c.union_all(query)
  |> c.order_by_asc("age")
  |> c.limit(1)
  |> c.offset(2)
  |> c.to_query
}

pub fn combined_union_all_test() {
  combined_union_all_query()
  |> to_string
  |> birdie.snap("combined_union_all_test")
}

pub fn combined_union_all_prepared_statement_test() {
  let pgo = combined_union_all_query() |> postgres.to_prepared_statement
  let lit = combined_union_all_query() |> sqlite.to_prepared_statement
  let mdb = combined_union_all_query() |> maria.to_prepared_statement
  let myq = combined_union_all_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_union_all_prepared_statement_test")
}

pub fn combined_union_all_execution_result_test() {
  let pgo = combined_union_all_query() |> postgres_test_helper.setup_and_run
  let lit = combined_union_all_query() |> sqlite_test_helper.setup_and_run
  let mdb = combined_union_all_query() |> maria_test_helper.setup_and_run
  let myq = combined_union_all_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_union_all_execution_result_test")
}

fn combined_intersect_query() {
  let query = query()
  query
  |> c.intersect(query)
  |> c.order_by_asc("age")
  |> c.limit(1)
  |> c.offset(2)
  |> c.to_query
}

pub fn combined_intersect_test() {
  combined_intersect_query()
  |> to_string
  |> birdie.snap("combined_intersect_test")
}

pub fn combined_intersect_prepared_statement_test() {
  let pgo = combined_intersect_query() |> postgres.to_prepared_statement
  let lit = combined_intersect_query() |> sqlite.to_prepared_statement
  let mdb = combined_intersect_query() |> maria.to_prepared_statement
  let myq = combined_intersect_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_intersect_prepared_statement_test")
}

pub fn combined_intersect_execution_result_test() {
  let pgo = combined_intersect_query() |> postgres_test_helper.setup_and_run
  let lit = combined_intersect_query() |> sqlite_test_helper.setup_and_run
  let mdb = combined_intersect_query() |> maria_test_helper.setup_and_run
  let myq = combined_intersect_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_intersect_execution_result_test")
}

fn combined_except_query() {
  let query = query()
  query
  |> c.except(query)
  |> c.order_by_asc("age")
  |> c.limit(1)
  |> c.offset(2)
  |> c.to_query
}

pub fn combined_except_test() {
  combined_except_query()
  |> to_string
  |> birdie.snap("combined_except_test")
}

pub fn combined_except_prepared_statement_test() {
  let pgo = combined_except_query() |> postgres.to_prepared_statement
  let lit = combined_except_query() |> sqlite.to_prepared_statement
  let mdb = combined_except_query() |> maria.to_prepared_statement
  let myq = combined_except_query() |> mysql.to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_except_prepared_statement_test")
}

pub fn combined_except_execution_result_test() {
  let pgo = combined_except_query() |> postgres_test_helper.setup_and_run
  let lit = combined_except_query() |> sqlite_test_helper.setup_and_run
  let mdb = combined_except_query() |> maria_test_helper.setup_and_run
  let myq = combined_except_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("combined_except_execution_result_test")
}
