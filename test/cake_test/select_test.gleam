import birdie
import cake/fragment as f
import cake/internal/read_query
import cake/select as s
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

const const_field = "age"

fn new_select() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([
    // Unsupported/buggy on POG, see <https://github.com/lpil/pog/pull/71>
    // s.bool(True), // Possibly a bug in Shork, to not be able to select a literal boolean
    // s.float(1.0),
    // s.int(1),
    s.col("name"),
    s.string("hello"),
    s.fragment(f.literal(const_field)),
    s.alias(s.col("age"), "years_since_birth"),
  ])
}

fn select_query() {
  new_select()
  |> s.selects([
    s.bool(True),
    s.float(1.0),
    s.int(1),
  ])
  |> s.to_query
}

fn select_mdb_myq_query() {
  new_select()
  |> s.selects([
    // Possibly a bug in <https://hex.pm/packages/shork>,
    // to not be able to select a literal boolean:
    // s.bool(True),
    s.float(1.0),
    s.int(1),
  ])
  |> s.to_query
}

fn replace_selects_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("a"), s.col("b")])
  |> s.replace_selects([s.col("c"), s.col("d")])
  |> s.to_query
}

fn select_pog_query() {
  new_select()
  // Unsupported/buggy on POG, see <https://github.com/lpil/pog/pull/71>
  // |> s.selects([
  //   s.bool(True),
  //   s.float(1.0),
  //   s.int(1),
  // ])
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_test() {
  select_query()
  |> to_string
  |> birdie.snap("select_test")
}

pub fn select_pog_test() {
  select_pog_query()
  |> to_string
  |> birdie.snap("select_pog_test")
}

pub fn select_mdb_myq_test() {
  select_mdb_myq_query()
  |> to_string
  |> birdie.snap("select_mdb_myq_test")
}

pub fn select_prepared_statement_test() {
  let pgo = select_pog_query() |> postgres.read_query_to_prepared_statement
  let lit = select_query() |> sqlite.read_query_to_prepared_statement
  let mdb = select_mdb_myq_query() |> maria.read_query_to_prepared_statement
  let myq = select_mdb_myq_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_prepared_statement_test")
}

pub fn select_execution_result_test() {
  let pgo = select_pog_query() |> postgres_test_helper.setup_and_run
  let lit = select_query() |> sqlite_test_helper.setup_and_run
  let mdb = select_mdb_myq_query() |> maria_test_helper.setup_and_run
  let myq = select_mdb_myq_query() |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("select_execution_result_test")
}

pub fn replace_selects_test() {
  replace_selects_query()
  |> to_string
  |> birdie.snap("replace_selects_test")
}

pub fn replace_selects_prepared_statement_test() {
  let pgo = replace_selects_query() |> postgres.read_query_to_prepared_statement
  let lit = replace_selects_query() |> sqlite.read_query_to_prepared_statement
  let mdb = replace_selects_query() |> maria.read_query_to_prepared_statement
  let myq = replace_selects_query() |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("replace_selects_prepared_statement_test")
}

pub fn replace_selects_execution_result_test() {
  // replace_selects_query() uses non-existent columns 'c'/'d'; use real
  // cats columns here to exercise replace_selects against a live database.
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.selects([s.col("name"), s.col("age")])
    |> s.replace_selects([s.col("name"), s.col("is_wild")])
    |> s.to_query

  let pgo = query |> postgres_test_helper.setup_and_run
  let lit = query |> sqlite_test_helper.setup_and_run
  let mdb = query |> maria_test_helper.setup_and_run
  let myq = query |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("replace_selects_execution_result_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Unit Tests                                                                │
// └───────────────────────────────────────────────────────────────────────────┘

/// `replace_select` must discard existing selects and keep only the new one.
///
/// Before the fix, the `Selects(_)` branch appended to the existing list
/// instead of replacing it, so calling `replace_select(col("c"))` on a query
/// that already had `[col("a"), col("b")]` would produce
/// `[col("a"), col("b"), col("c")]` rather than `[col("c")]`.
///
pub fn replace_select_replaces_existing_test() {
  assert s.new()
    |> s.selects([s.col("a"), s.col("b")])
    |> s.replace_select(s.col("c"))
    |> s.get_select
    == read_query.Selects([read_query.SelectColumn("c")])
}

/// `replace_selects` must discard existing selects and keep only the new list.
///
/// Same root cause as `replace_select`: the `Selects(_)` branch was appending
/// rather than replacing, so `replace_selects([col("c"), col("d")])` on a
/// query with `[col("a"), col("b")]` would wrongly yield all four columns.
///
pub fn replace_selects_replaces_existing_test() {
  assert s.new()
    |> s.selects([s.col("a"), s.col("b")])
    |> s.replace_selects([s.col("c"), s.col("d")])
    |> s.get_select
    == read_query.Selects([
      read_query.SelectColumn("c"),
      read_query.SelectColumn("d"),
    ])
}

/// When the replacement list is empty, `replace_selects` must leave the
/// existing selects unchanged (the `[], _` guard).
///
pub fn replace_selects_empty_list_is_noop_test() {
  assert s.new()
    |> s.selects([s.col("a"), s.col("b")])
    |> s.replace_selects([])
    |> s.get_select
    == read_query.Selects([
      read_query.SelectColumn("a"),
      read_query.SelectColumn("b"),
    ])
}
