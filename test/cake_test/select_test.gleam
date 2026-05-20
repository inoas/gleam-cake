import birdie
import cake/fragment as f
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
// │  Tests                                                                    │
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
