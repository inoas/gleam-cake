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

/// Snapshots the generated SQL for an `ON CONFLICT … DO NOTHING` with an index
/// predicate `WHERE` across all four dialects.
///
/// Correct order: ON CONFLICT (name) WHERE counters.is_active IS TRUE DO NOTHING
/// Bug order:     ON CONFLICT (name) DO NOTHING WHERE counters.is_active IS TRUE
///
/// The snapshot captures the current (buggy) output.  Once bug 6 is fixed the
/// snapshot must be updated to reflect the corrected clause ordering.
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

/// Executes the insert against all four databases and snapshots the results.
///
/// With the current bug the generated SQL has `DO NOTHING WHERE …` which is
/// invalid syntax, so all four engines return an error.  Once bug 6 is fixed
/// the clause order becomes `WHERE … DO NOTHING`; 🐘PostgreSQL and 🪶SQLite
/// will then execute successfully, while 🦭MariaDB and 🐬MySQL are expected to
/// return an error because they do not support the `ON CONFLICT` syntax.
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
