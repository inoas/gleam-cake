import birdie
import cake/insert as i
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

fn insert_on_conflict_ignore_with_where_query() {
  [[i.string("Whiskers"), i.int(1)] |> i.row]
  |> i.from_values(table_name: "counters", columns: ["name", "counter"])
  |> i.on_columns_conflict_ignore(
    columns: ["name"],
    where: w.col("counters.is_active") |> w.is_true,
  )
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Proves that `ON CONFLICT … DO NOTHING` with an index predicate emits
/// clauses in the correct order across all four dialects:
/// `ON CONFLICT (name) WHERE … IS TRUE DO NOTHING`.
///
pub fn insert_on_conflict_ignore_where_ordering_test() {
  let query = insert_on_conflict_ignore_with_where_query()

  let pgo = query |> postgres.write_query_to_prepared_statement
  let lit = query |> sqlite.write_query_to_prepared_statement
  let mdb = query |> maria.write_query_to_prepared_statement
  let myq = query |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_on_conflict_ignore_where_ordering_test")
}

/// Proves execution results for an `ON CONFLICT (name) WHERE … DO NOTHING`
/// insert across all four databases. 🐘PostgreSQL and 🪶SQLite execute
/// the statement directly; 🦭MariaDB and 🐬MySQL translate it to a
/// `SELECT … WHERE NOT EXISTS` upsert.
///
pub fn insert_on_conflict_ignore_where_ordering_execution_result_test() {
  let query = insert_on_conflict_ignore_with_where_query()

  let pgo = query |> postgres_test_helper.setup_and_run_write
  let lit = query |> sqlite_test_helper.setup_and_run_write
  let mdb = query |> maria_test_helper.setup_and_run_write
  let myq = query |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(
    "insert_on_conflict_ignore_where_ordering_execution_result_test",
  )
}
