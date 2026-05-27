import birdie
import cake/select as s
import pprint.{format as to_string}
import test_support/adapter/postgres

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Tests for order_by_append behavior                                        │
// └───────────────────────────────────────────────────────────────────────────┘
//
// The order_by_append function is internal to read_query.gleam, but we can
// test its behavior through the public API by calling order_by functions
// multiple times.

pub fn order_by_append_no_order_to_asc_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc("name")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_no_order_to_asc_test")
}

pub fn order_by_append_no_order_to_desc_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_desc("age")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_no_order_to_desc_test")
}

pub fn order_by_append_asc_then_asc_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc("name")
  |> s.order_by_asc("age")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_asc_then_asc_test")
}

pub fn order_by_append_asc_then_desc_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc("name")
  |> s.order_by_desc("age")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_asc_then_desc_test")
}

pub fn order_by_append_desc_then_asc_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_desc("name")
  |> s.order_by_asc("age")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_desc_then_asc_test")
}

pub fn order_by_append_multiple_columns_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc("name")
  |> s.order_by_desc("age")
  |> s.order_by_asc("rating")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_multiple_columns_test")
}

pub fn order_by_append_with_nulls_first_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc_nulls_first("name")
  |> s.order_by_desc("age")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_with_nulls_first_test")
}

pub fn order_by_append_with_nulls_last_test() {
  s.new()
  |> s.from_table("cats")
  |> s.select(s.col("name"))
  |> s.order_by_asc("name")
  |> s.order_by_desc_nulls_last("rating")
  |> s.to_query
  |> postgres.read_query_to_prepared_statement
  |> to_string
  |> birdie.snap(title: "order_by_append_with_nulls_last_test")
}
