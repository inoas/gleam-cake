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
// │  Setup                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn where_like_similar_to_pg_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.or([
      w.col("name") |> w.like("%inn%"),
      w.col("name") |> w.ilike("KAR%"),
      w.col("name") |> w.similar_to("Clar", "/"),
    ]),
  )
  |> s.to_query
}

fn where_like_similar_to_sqlite_mariadb_mysql_query() {
  s.new()
  |> s.from_table("cats")
  |> s.where(
    w.or([
      w.col("name") |> w.like("%inn%"),
      // 🪶SQLite, 🦭MariaDB, and 🐬MySQL do not support ILIKE or SIMILAR TO
    // w.col("name") |> w.ilike("KAR%"),
    // w.col("name") |> w.similar_to("Clar", "/"),
    ]),
  )
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Tests                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn where_like_similar_to_test() {
  let pgo = where_like_similar_to_pg_query()
  let lit = where_like_similar_to_sqlite_mariadb_mysql_query()
  let mdb = where_like_similar_to_sqlite_mariadb_mysql_query()
  let myq = where_like_similar_to_sqlite_mariadb_mysql_query()

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_like_similar_to_test")
}

pub fn where_like_similar_to_prepared_statement_test() {
  let pgo =
    where_like_similar_to_pg_query()
    |> postgres.read_query_to_prepared_statement
  let lit =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> sqlite.read_query_to_prepared_statement
  let mdb =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> maria.read_query_to_prepared_statement
  let myq =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_like_similar_to_prepared_statement_test")
}

pub fn where_like_similar_to_execution_result_test() {
  let pgo =
    where_like_similar_to_pg_query() |> postgres_test_helper.setup_and_run
  let lit =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> sqlite_test_helper.setup_and_run
  let mdb =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> maria_test_helper.setup_and_run
  let myq =
    where_like_similar_to_sqlite_mariadb_mysql_query()
    |> mysql_test_helper.setup_and_run

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("where_like_similar_to_execution_result_test")
}
