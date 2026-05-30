import birdie
import cake
import cake/fragment as f
import cake/param as p
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

fn sub_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.where(w.col("name") |> w.eq(w.string("Karl")))
  |> s.to_query
}

fn where_in_query_query() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  // Regular IN
  |> s.where(w.col("age") |> w.in([w.int(1), w.int(2), w.int(3)]))
  // IN sub_query
  |> s.or_where(w.col("name") |> w.in_query(sub_query()))
  // IN sub_query could also work like such:
  |> s.or_where(
    w.col("name") |> w.in([w.string("Clara"), w.sub_query(sub_query())]),
  )
  // `WHERE a NOT IN b` (or rather `WHERE NOT(a IN b)`)
  |> s.where(w.not(w.col("age") |> w.in([w.int(99), w.int(98), w.int(97)])))
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_in_query_test() {
  where_in_query_query()
  |> to_string
  |> birdie.snap("where_in_query_test")
}

pub fn where_in_query_prepared_statement_test() {
  let pgo = where_in_query_query() |> postgres.read_query_to_prepared_statement
  let lit = where_in_query_query() |> sqlite.read_query_to_prepared_statement
  let mdb = where_in_query_query() |> maria.read_query_to_prepared_statement
  let myq = where_in_query_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_query_prepared_statement_test")
}

pub fn where_in_query_execution_result_test() {
  let pgo = where_in_query_query() |> postgres_test_helper.setup_and_run
  let lit = where_in_query_query() |> sqlite_test_helper.setup_and_run
  let mdb = where_in_query_query() |> maria_test_helper.setup_and_run
  let myq = where_in_query_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_query_execution_result_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Unit Tests                                                                │
// └───────────────────────────────────────────────────────────────────────────┘

/// `IN` list with a `WhereParamValue` followed by a `WhereFragmentValue`.
///
/// The fragment must use the running prepared-statement accumulator so the
/// preceding param is not discarded; before the fix it would have been,
/// causing `IntParam(1)` to be lost and the fragment's param to receive
/// placeholder index `$1` instead of `$2`.
///
pub fn where_in_fragment_value_prepared_statement_accumulator_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.where(
      w.col("cats.age")
      |> w.in([
        w.int(1),
        w.fragment_value(f.prepared(f.placeholder, [f.int(2)])),
      ]),
    )
    |> s.to_query

  let expected_params = [p.IntParam(1), p.IntParam(2)]

  assert query
    |> postgres.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> sqlite.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> maria.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> mysql.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params
}

pub fn where_in_fragment_value_execution_result_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.where(
      w.col("cats.age")
      |> w.in([
        w.int(1),
        w.fragment_value(f.prepared(f.placeholder, [f.int(2)])),
      ]),
    )
    |> s.to_query

  let pgo = query |> postgres_test_helper.setup_and_run
  let lit = query |> sqlite_test_helper.setup_and_run
  let mdb = query |> maria_test_helper.setup_and_run
  let myq = query |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_fragment_value_execution_result_test")
}

/// `IN` list with a `WhereParamValue`, a parameterless `WhereSubQueryValue`,
/// and another `WhereParamValue`.
///
/// The sub-query must use the running prepared-statement accumulator so the
/// preceding param is not discarded and the trailing param's placeholder index
/// continues correctly; before the fix the accumulator would have been reset,
/// causing `StringParam("Alice")` to be lost and `StringParam("Bob")` to
/// receive placeholder index `$1` instead of `$2`.
///
pub fn where_in_sub_query_value_prepared_statement_accumulator_test() {
  let new_sub_q =
    s.new()
    |> s.from_table("owners")
    |> s.select(s.col("name"))
    |> s.to_query

  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.where(
      w.col("cats.name")
      |> w.in([
        w.string("Alice"),
        w.sub_query(new_sub_q),
        w.string("Bob"),
      ]),
    )
    |> s.to_query

  let expected_params = [p.StringParam("Alice"), p.StringParam("Bob")]

  assert query
    |> postgres.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> sqlite.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> maria.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params

  assert query
    |> mysql.read_query_to_prepared_statement
    |> cake.get_params
    == expected_params
}

pub fn where_in_sub_query_value_execution_result_test() {
  let new_sub_q =
    s.new()
    |> s.from_table("owners")
    |> s.select(s.col("name"))
    |> s.limit(1)
    |> s.to_query

  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.where(
      w.col("cats.name")
      |> w.in([
        w.string("Alice"),
        w.sub_query(new_sub_q),
        w.string("Bob"),
      ]),
    )
    |> s.to_query

  let pgo = query |> postgres_test_helper.setup_and_run
  let lit = query |> sqlite_test_helper.setup_and_run
  let mdb = query |> maria_test_helper.setup_and_run
  let myq = query |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_in_sub_query_value_execution_result_test")
}
