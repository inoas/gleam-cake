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
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn fragment_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.fragment_value(f.literal("LOWER(cats.name)"))
    |> w.eq(
      w.fragment_value(
        f.prepared("LOWER(" <> f.placeholder <> ")", [f.string("cLaRa")]),
      ),
    ),
  )
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn fragment_test() {
  fragment_query()
  |> to_string
  |> birdie.snap("fragment_test")
}

pub fn fragment_prepared_statement_test() {
  let pgo = fragment_query() |> postgres.read_query_to_prepared_statement
  let lit = fragment_query() |> sqlite.read_query_to_prepared_statement
  let mdb = fragment_query() |> maria.read_query_to_prepared_statement
  let myq = fragment_query() |> mysql.read_query_to_prepared_statement

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

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Unit Tests                                                               │
// └───────────────────────────────────────────────────────────────────────────┘

/// Excess params (more params than placeholders): the extra param must be
/// discarded so the resulting param list length matches the placeholder count.
pub fn fragment_prepared_exceeding_params_test() {
  let query =
    s.new()
    |> s.from_table("t")
    |> s.where(
      w.fragment(
        f.prepared(f.placeholder <> " + " <> f.placeholder, [
          f.int(1),
          f.int(2),
          f.int(3),
        ]),
      ),
    )
    |> s.to_query

  let expected = [p.IntParam(1), p.IntParam(2)]

  assert query
    |> postgres.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> sqlite.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> maria.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> mysql.read_query_to_prepared_statement
    |> cake.get_params
    == expected
}

/// Excess placeholders (more placeholders than params):
/// The last param must be repeated to fill the remaining placeholder positions.
pub fn fragment_prepared_exceeding_placeholders_test() {
  let query =
    s.new()
    |> s.from_table("t")
    |> s.where(
      w.fragment(
        f.prepared(
          f.placeholder <> " + " <> f.placeholder <> " + " <> f.placeholder,
          [f.int(10), f.int(20)],
        ),
      ),
    )
    |> s.to_query

  let expected = [p.IntParam(10), p.IntParam(20), p.IntParam(20)]

  assert query
    |> postgres.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> sqlite.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> maria.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> mysql.read_query_to_prepared_statement
    |> cake.get_params
    == expected
}

/// Zero placeholders and zero params:
/// The fragment is treated as a literal and no params are emitted.
pub fn fragment_prepared_zero_params_and_zero_placeholders_test() {
  let query =
    s.new()
    |> s.from_table("t")
    |> s.where(w.fragment(f.prepared("1 = 1", [])))
    |> s.to_query

  let expected = []

  assert query
    |> postgres.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> sqlite.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> maria.read_query_to_prepared_statement
    |> cake.get_params
    == expected

  assert query
    |> mysql.read_query_to_prepared_statement
    |> cake.get_params
    == expected
}
