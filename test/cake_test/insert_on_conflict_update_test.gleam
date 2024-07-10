import birdie
import cake/insert as i
import cake/internal/query.{AndWhere}
import cake/update as u
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

fn update_query() {
  u.new()
  |> u.table("counters")
  |> u.sets(["counter" |> u.set_to_expression("counter + 1")])
}

fn insert_on_conflict_update_values() {
  let counter =
    [
      i.param(column: "name", param: "Whiskers" |> i.string),
      i.param(column: "counter", param: 0 |> i.int),
    ]
    |> i.row

  let conflict_where = AndWhere([w.col("name") |> w.is_not_null()])

  i.from_values(table_name: "counters", columns: ["name", "counter"], values: [
    counter,
  ])
  |> i.on_columns_conflict_update(
    column: ["counter"],
    where: conflict_where,
    update: update_query(),
  )
  |> i.returning(["name"])
}

fn insert_on_conflict_update_values_query() {
  insert_on_conflict_update_values()
  |> i.to_query
}

fn insert_on_conflict_update_values_maria_mysql_query() {
  // MariaDB/MySQL do not support `RETURNING` in `INSERT` queries:
  insert_on_conflict_update_values()
  |> i.no_returning
  |> i.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Test                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn insert_on_conflict_update_values_test() {
  let pgo = insert_on_conflict_update_values_query()
  let lit = pgo
  let mdb = insert_on_conflict_update_values_maria_mysql_query()
  let myq = mdb

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_test")
}

pub fn insert_on_conflict_update_values_prepared_statement_test() {
  let pgo =
    insert_on_conflict_update_values_query()
    |> postgres.write_query_to_prepared_statement
  let lit =
    insert_on_conflict_update_values_query()
    |> sqlite.write_query_to_prepared_statement
  let mdb =
    insert_on_conflict_update_values_maria_mysql_query()
    |> maria.write_query_to_prepared_statement
  let myq =
    insert_on_conflict_update_values_maria_mysql_query()
    |> mysql.write_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_prepared_statement_test")
}

pub fn insert_on_conflict_update_values_execution_result_test() {
  let pgo =
    insert_on_conflict_update_values_query()
    |> postgres_test_helper.setup_and_run_write
  let lit =
    insert_on_conflict_update_values_query()
    |> sqlite_test_helper.setup_and_run_write
  let mdb =
    insert_on_conflict_update_values_maria_mysql_query()
    |> maria_test_helper.setup_and_run_write
  let myq =
    insert_on_conflict_update_values_maria_mysql_query()
    |> mysql_test_helper.setup_and_run_write

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("insert_on_conflict_update_values_execution_result_test")
}
