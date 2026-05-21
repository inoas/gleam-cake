import birdie
import cake/delete as d
import cake/insert as i
import cake/update as u
import pprint.{format as to_string}
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

fn delete_query() {
  d.new()
  |> d.table("cats")
  |> d.epilog("FOR SHARE")
  |> d.comment("trace id 42")
  |> d.to_query
}

fn update_query() {
  u.new()
  |> u.table("cats")
  |> u.sets(["name" |> u.set_string("Nubi")])
  |> u.epilog("FOR SHARE")
  |> u.comment("trace id 42")
  |> u.to_query
}

fn insert_query() {
  [[i.string("Nubi")] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name"])
  |> i.epilog("FOR SHARE")
  |> i.comment("trace id 42")
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Bug 8: a single-line `--` comment is emitted before the epilog, which
/// causes the SQL parser to treat the epilog as part of the comment and
/// silently ignore it.
///
/// Correct order: … <epilog> -- <comment>
/// Bug order:     … -- <comment> <epilog>      ← epilog is commented-out
///
pub fn delete_epilog_after_comment_prepared_statement_test() {
  let pgo = delete_query() |> postgres.write_query_to_prepared_statement
  let lit = delete_query() |> sqlite.write_query_to_prepared_statement
  let mdb = delete_query() |> maria.write_query_to_prepared_statement
  let myq = delete_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("delete_epilog_after_comment_prepared_statement_test")
}

pub fn update_epilog_after_comment_prepared_statement_test() {
  let pgo = update_query() |> postgres.write_query_to_prepared_statement
  let lit = update_query() |> sqlite.write_query_to_prepared_statement
  let mdb = update_query() |> maria.write_query_to_prepared_statement
  let myq = update_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("update_epilog_after_comment_prepared_statement_test")
}

pub fn insert_epilog_after_comment_prepared_statement_test() {
  let pgo = insert_query() |> postgres.write_query_to_prepared_statement
  let lit = insert_query() |> sqlite.write_query_to_prepared_statement
  let mdb = insert_query() |> maria.write_query_to_prepared_statement
  let myq = insert_query() |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_epilog_after_comment_prepared_statement_test")
}
