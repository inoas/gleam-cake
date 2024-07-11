import birdie
import cake/fragment as f
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

fn where_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.or([
      w.col("age") |> w.lt(w.int(100)),
      w.col("age") |> w.lte(w.int(99)),
      w.col("age") |> w.eq(w.int(50)),
      w.col("age") |> w.gt(w.int(10)),
      w.col("age") |> w.gte(w.int(9)),
    ]),
  )
  |> s.where(w.fragment(f.literal("1 = 1")))
  |> s.where(
    w.or([
      w.col("name") |> w.eq(w.string("Karl")),
      w.col("name") |> w.eq(w.string("Clara")),
    ]),
  )
  |> s.where(
    w.or([
      w.col("is_wild") |> w.is_false,
      w.col("is_wild") |> w.is_true,
      w.col("is_wild") |> w.is_bool(False),
      w.col("is_wild") |> w.is_bool(True),
      w.col("is_wild") |> w.is_not_bool(False),
      w.col("is_wild") |> w.is_not_bool(True),
      w.col("is_wild") |> w.is_null,
      w.col("is_wild") |> w.is_not_null,
    ]),
  )
  |> s.where(
    w.or([
      w.not(w.col("rating") |> w.gt(w.float(0.0))),
      w.not(w.col("rating") |> w.is_null),
    ]),
  )
  |> s.to_query
}

fn where_any_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.col("owner_id")
    |> w.eq_any_query(
      s.new()
      |> s.from_table("dogs")
      |> s.selects([s.col("owner_id")])
      |> s.to_query,
    ),
  )
  |> s.to_query
}

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
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_test() {
  where_query()
  |> to_string
  |> birdie.snap("where_test")
}

pub fn where_prepared_statement_test() {
  let pgo = where_query() |> postgres.read_query_to_prepared_statement
  let lit = where_query() |> sqlite.read_query_to_prepared_statement
  let mdb = where_query() |> maria.read_query_to_prepared_statement
  let myq = where_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_prepared_statement_test")
}

pub fn where_execution_result_test() {
  let pgo = where_query() |> postgres_test_helper.setup_and_run
  let lit = where_query() |> sqlite_test_helper.setup_and_run
  let mdb = where_query() |> maria_test_helper.setup_and_run
  let myq = where_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_execution_result_test")
}

pub fn where_any_test() {
  where_any_query()
  |> to_string
  |> birdie.snap("where_any_test")
}

pub fn where_any_prepared_statement_test() {
  let pgo = where_any_query() |> postgres.read_query_to_prepared_statement
  let lit = where_any_query() |> sqlite.read_query_to_prepared_statement
  let mdb = where_any_query() |> maria.read_query_to_prepared_statement
  let myq = where_any_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_any_prepared_statement_test")
}

pub fn where_any_execution_result_test() {
  let pgo = where_any_query() |> postgres_test_helper.setup_and_run
  // This is supposed to fail because SQLite does not support ´ANY´:
  let lit = where_any_query() |> sqlite_test_helper.setup_and_run
  let mdb = where_any_query() |> maria_test_helper.setup_and_run
  let myq = where_any_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_any_execution_result_test")
}

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
