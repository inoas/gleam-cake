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
// │ Background                                                                │
// └───────────────────────────────────────────────────────────────────────────┘
//
// This test documents findings about float handling in conjunction with
// MySQL/MariaDB on Erlang/BEAM versus other adapters such as Sqlite and
// Postgres.
//
// The cats table declares `rating FLOAT(8)`.
//
// PostgreSQL: FLOAT(p) with p ≤ 24 is a 32-bit single-precision column.
//   The driver returns the stored bits widened to a 64-bit Erlang float, so
//   1.1 comes back as 1.100000023841858 (the nearest double to the nearest
//   single).
//
// SQLite: REAL is always 64-bit. The SQL literal `1.1` is inserted as the
//   nearest IEEE-754 double, so it round-trips exactly as 1.1.
//
// MariaDB/MySQL: FLOAT(8) is also 32-bit single-precision, but the text
//   protocol returns the value rounded to fewer digits, so Erlang sees 1.1
//   rather than the widened double.
//
// Consequence for equality comparisons with a bound FloatParam(1.1):
//   The Erlang literal 1.1 becomes the nearest IEEE-754 double
//   (≈ 1.1000000000000001), which differs from the stored single-precision
//   value (≈ 1.100000023841858) when compared as doubles.
//
//   PostgreSQL narrows the double parameter to the column's 32-bit type
//   before comparing → both sides are the same single-precision bits → TRUE.
//
//   SQLite stored 64-bit 1.1; the parameter is also 64-bit 1.1 → same bits
//   → TRUE.
//
//   MariaDB/MySQL compare at double precision without narrowing → the stored
//   single (1.100000023…) ≠ the double parameter (1.10000000000…) → FALSE.

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Reads back every non-null rating value so the snapshot documents the
/// raw float representation each adapter returns for a 32-bit stored value.
///
/// PostgreSQL returns 1.1 as 1.100000023841858 and 2.2 as 2.200000047683716
/// (the nearest double to each single-precision stored value).
/// SQLite and MariaDB/MySQL return 1.1 and 2.2 (text-rounded or 64-bit exact).
fn float_precision_stored_values_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("name"), s.col("rating")])
  |> s.where(w.col("rating") |> w.is_not_null)
  |> s.order_by_asc("name")
  |> s.to_query
}

/// Filters cats where rating = 1.1 using a bound double-precision parameter.
///
/// Only Biffy has a stored rating of 1.1 (single-precision).
///
/// PostgreSQL narrows the double parameter to single before comparing
/// → 1.1 (single) = 1.1 (single) → TRUE → Biffy matches.
///
/// SQLite stored 64-bit 1.1; the double parameter is the same bits
/// → TRUE → Biffy matches.
///
/// MariaDB/MySQL compare in double precision without narrowing:
/// stored 1.100000023… ≠ double 1.10000000000… → FALSE → no match.
///
/// Expected on 🐘PostgreSQL / 🪶SQLite:  Biffy.
/// Expected on 🦭MariaDB / 🐬MySQL:      nobody.
fn float_precision_eq_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("name"), s.col("rating")])
  |> s.where(w.col("rating") |> w.eq(w.float(1.1)))
  |> s.order_by_asc("name")
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests — stored float values                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn float_precision_stored_values_test() {
  float_precision_stored_values_query()
  |> to_string
  |> birdie.snap("float_precision_stored_values_test")
}

pub fn float_precision_stored_values_prepared_statement_test() {
  let pgo =
    float_precision_stored_values_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    float_precision_stored_values_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    float_precision_stored_values_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    float_precision_stored_values_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("float_precision_stored_values_prepared_statement_test")
}

pub fn float_precision_stored_values_execution_result_test() {
  let pgo =
    float_precision_stored_values_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    float_precision_stored_values_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    float_precision_stored_values_query()
    |> maria_test_helper.setup_and_run
  let myq =
    float_precision_stored_values_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("float_precision_stored_values_execution_result_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests — float equality with a double-precision parameter                 │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn float_precision_eq_test() {
  float_precision_eq_query()
  |> to_string
  |> birdie.snap("float_precision_eq_test")
}

pub fn float_precision_eq_prepared_statement_test() {
  let pgo =
    float_precision_eq_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    float_precision_eq_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    float_precision_eq_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    float_precision_eq_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("float_precision_eq_prepared_statement_test")
}

pub fn float_precision_eq_execution_result_test() {
  let pgo =
    float_precision_eq_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    float_precision_eq_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    float_precision_eq_query()
    |> maria_test_helper.setup_and_run
  let myq =
    float_precision_eq_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("float_precision_eq_execution_result_test")
}
