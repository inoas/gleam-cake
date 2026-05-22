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

fn where_xor_parity_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.xor_parity([
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

pub fn where_xor_parity_test() {
  where_xor_parity_query()
  |> to_string
  |> birdie.snap("where_xor_parity_test")
}

pub fn where_xor_parity_prepared_statement_test() {
  let pgo =
    where_xor_parity_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    where_xor_parity_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    where_xor_parity_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    where_xor_parity_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_prepared_statement_test")
}

pub fn where_xor_parity_execution_result_test() {
  let pgo =
    where_xor_parity_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    where_xor_parity_query()
    |> sqlite_test_helper.setup_and_run
  let mdb = where_xor_parity_query() |> maria_test_helper.setup_and_run
  let myq = where_xor_parity_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_execution_result_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup — xor_parity with NULL checks                                       │
// └───────────────────────────────────────────────────────────────────────────┘

/// Selects name, is_wild, and rating for every cat so the snapshot proves
/// exactly what each adapter stores for both nullable columns before the
/// parity tests draw any conclusions from them.
/// Biffy has is_wild = NULL; Ginny has rating = NULL.
fn where_xor_parity_null_data_check_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("name"), s.col("is_wild"), s.col("rating")])
  |> s.order_by_asc("name")
  |> s.to_query
}

/// NULL-poisoning test for a BOOLEAN nullable column (is_wild).
///
/// `is_wild = TRUE` (plain equality) returns NULL when is_wild IS NULL,
/// unlike `is_wild IS TRUE` which coerces NULL to FALSE.
///
/// Biffy has is_wild = NULL:
///   age > 5 → TRUE,  is_wild = TRUE → NULL
///   (1 + NULL) % 2 = NULL → WHERE discards the row.
///
/// Biffy is absent on all four adapters, confirming NULL-poisoning works
/// consistently for boolean columns.
///
/// **BoolParam encoding:** MariaDB and MySQL store booleans as TINYINT(1).
/// Their Erlang driver (mysql_encode) has no clause for Erlang boolean atoms,
/// so the adapters convert BoolParam to shork.int(1 or 0) before binding.
/// The prepared-statement representation still shows BoolParam(True) as the
/// logical param type; the int conversion is an adapter-level detail.
///
/// Expected matches:     Nubi (0+1=1), Ginny (1+0=1), Clara (0+1=1).
/// Expected non-match:   Biffy — poisoned by NULL is_wild (all adapters).
fn where_xor_parity_null_bool_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.xor_parity([
      w.col("age") |> w.gt(w.int(5)),
      w.col("is_wild") |> w.eq(w.true()),
    ]),
  )
  |> s.to_query
}

/// NULL-poisoning test for a FLOAT nullable column (rating).
///
/// `rating = 1.1` (plain equality) returns NULL when rating IS NULL.
///
/// Ginny has rating = NULL:
///   age > 5 → TRUE,  rating = 1.1 → NULL
///   (1 + NULL) % 2 = NULL → WHERE discards the row.
///
/// Ginny is absent on all four adapters, confirming NULL-poisoning works
/// consistently for float columns.
///
/// **Note — Biffy appears only on MariaDB/MySQL:** this is a float precision
/// artifact, not a NULL issue. PostgreSQL and SQLite use 64-bit doubles for
/// FLOAT(8), so `rating = 1.1` (double) matches Biffy’s stored `1.1`
/// (same bits → TRUE), and TRUE XOR TRUE = 2 trues = even = no match.
/// MariaDB/MySQL use a 32-bit single-precision FLOAT, which rounds to
/// `1.100000023…` when widened to 64-bit; the double parameter `1.1`
/// does not equal that value (FALSE), so TRUE XOR FALSE = 1 true = odd
/// = match. Both outcomes are correct given each engine’s storage type.
///
/// Expected on 🐘PostgreSQL / 🪶SQLite:  Karl only (1+0=1, Ginny absent).
/// Expected on 🦭MariaDB / 🐬MySQL:         Biffy, Karl (Ginny still absent).
fn where_xor_parity_null_float_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.xor_parity([
      w.col("age") |> w.gt(w.int(5)),
      w.col("rating") |> w.eq(w.float(1.1)),
    ]),
  )
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests — xor_parity with NULL checks                                       │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_xor_parity_null_data_check_test() {
  let pgo =
    where_xor_parity_null_data_check_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    where_xor_parity_null_data_check_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    where_xor_parity_null_data_check_query()
    |> maria_test_helper.setup_and_run
  let myq =
    where_xor_parity_null_data_check_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_null_data_check_test")
}

pub fn where_xor_parity_null_bool_test() {
  where_xor_parity_null_bool_query()
  |> to_string
  |> birdie.snap("where_xor_parity_null_bool_test")
}

pub fn where_xor_parity_null_bool_prepared_statement_test() {
  let pgo =
    where_xor_parity_null_bool_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    where_xor_parity_null_bool_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    where_xor_parity_null_bool_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    where_xor_parity_null_bool_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_null_bool_prepared_statement_test")
}

pub fn where_xor_parity_null_bool_execution_result_test() {
  let pgo =
    where_xor_parity_null_bool_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    where_xor_parity_null_bool_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    where_xor_parity_null_bool_query()
    |> maria_test_helper.setup_and_run
  let myq =
    where_xor_parity_null_bool_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_null_bool_execution_result_test")
}

pub fn where_xor_parity_null_float_test() {
  where_xor_parity_null_float_query()
  |> to_string
  |> birdie.snap("where_xor_parity_null_float_test")
}

pub fn where_xor_parity_null_float_prepared_statement_test() {
  let pgo =
    where_xor_parity_null_float_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    where_xor_parity_null_float_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    where_xor_parity_null_float_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    where_xor_parity_null_float_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_null_float_prepared_statement_test")
}

pub fn where_xor_parity_null_float_execution_result_test() {
  let pgo =
    where_xor_parity_null_float_query()
    |> postgres_test_helper.setup_and_run
  let lit =
    where_xor_parity_null_float_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    where_xor_parity_null_float_query()
    |> maria_test_helper.setup_and_run
  let myq =
    where_xor_parity_null_float_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_xor_parity_null_float_execution_result_test")
}
