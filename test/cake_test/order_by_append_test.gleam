import birdie
import cake/select as s
import pprint.{format as to_string}
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests for order_by_append behavior                                        │
// └───────────────────────────────────────────────────────────────────────────┘
//
// The order_by_append function is internal to read_query.gleam, but we can
// test its behavior through the public API by calling order_by functions
// multiple times.

pub fn order_by_append_no_order_to_asc_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc("name")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_no_order_to_asc_test")
}

pub fn order_by_append_no_order_to_desc_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_desc("age")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_no_order_to_desc_test")
}

pub fn order_by_append_asc_then_asc_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc("name")
    |> s.order_by_asc("age")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_asc_then_asc_test")
}

pub fn order_by_append_asc_then_desc_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc("name")
    |> s.order_by_desc("age")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_asc_then_desc_test")
}

pub fn order_by_append_desc_then_asc_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_desc("name")
    |> s.order_by_asc("age")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_desc_then_asc_test")
}

pub fn order_by_append_multiple_columns_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc("name")
    |> s.order_by_desc("age")
    |> s.order_by_asc("rating")
    |> s.to_query

  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement
  let mdb = query |> maria.read_query_to_prepared_statement
  let myq = query |> mysql.read_query_to_prepared_statement

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap(title: "order_by_append_multiple_columns_test")
}

pub fn order_by_append_with_nulls_first_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc_nulls_first("name")
    |> s.order_by_desc("age")
    |> s.to_query

  // NULLS FIRST/LAST not supported by MariaDB and MySQL
  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap(title: "order_by_append_with_nulls_first_test")
}

pub fn order_by_append_with_nulls_last_test() {
  let query =
    s.new()
    |> s.from_table("cats")
    |> s.select(s.col("name"))
    |> s.order_by_asc("name")
    |> s.order_by_desc_nulls_last("rating")
    |> s.to_query

  // NULLS FIRST/LAST not supported by MariaDB and MySQL
  let pgo = query |> postgres.read_query_to_prepared_statement
  let lit = query |> sqlite.read_query_to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap(title: "order_by_append_with_nulls_last_test")
}
