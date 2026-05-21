// Tests for the bug where calling `.joins(query, [])` — an empty list — on a
// query that already has joins incorrectly replaces the existing joins with
// `Joins([])` instead of leaving the query unchanged.
//
// Root cause: the first arm of each `joins` function was
//
//   [], _ -> X(..x, join: joins |> Joins)
//
// which creates `Joins([])` (shadowing the outer `joins = []` variable).
// The correct behaviour, consistent with the `selects` function, is
//
//   [], _ -> x
//
// i.e. return the query unchanged when the new-joins list is empty.

import birdie
import cake/delete as d
import cake/join as j
import cake/select as s
import cake/update as u
import cake/where as w
import pprint.{format as to_string}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Setup helpers                                                             │
// └───────────────────────────────────────────────────────────────────────────┘

fn cross_join() {
  j.cross(with: j.table("dogs"), alias: "dogs")
}

fn inner_join() {
  j.inner(
    with: j.table("cats"),
    alias: "cats",
    on: w.col("cats.owner_id") |> w.eq(w.col("owners.id")),
  )
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Select – joins([]) must NOT overwrite existing joins                      │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn select_joins_empty_preserves_existing_test() {
  s.new()
  |> s.from_table("owners")
  |> s.select(s.col("owners.name"))
  |> s.join(cross_join())
  // calling joins([]) on a query that already has a join should be a no-op
  |> s.joins([])
  |> s.to_query
  |> to_string
  |> birdie.snap("select_joins_empty_preserves_existing_test")
}

pub fn select_joins_empty_on_empty_query_test() {
  s.new()
  |> s.from_table("owners")
  |> s.select(s.col("owners.name"))
  // calling joins([]) on a query with no joins should also be a no-op
  |> s.joins([])
  |> s.to_query
  |> to_string
  |> birdie.snap("select_joins_empty_on_empty_query_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Delete – joins([]) must NOT overwrite existing joins                      │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn delete_joins_empty_preserves_existing_test() {
  d.new()
  |> d.table("owners")
  |> d.join(inner_join())
  // calling joins([]) on a query that already has a join should be a no-op
  |> d.joins([])
  |> d.to_query
  |> to_string
  |> birdie.snap("delete_joins_empty_preserves_existing_test")
}

pub fn delete_joins_empty_on_empty_query_test() {
  d.new()
  |> d.table("owners")
  // calling joins([]) on a query with no joins should also be a no-op
  |> d.joins([])
  |> d.to_query
  |> to_string
  |> birdie.snap("delete_joins_empty_on_empty_query_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Update – joins([]) must NOT overwrite existing joins                      │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn update_joins_empty_preserves_existing_test() {
  u.new()
  |> u.table("owners")
  |> u.set("name" |> u.set_string("Alice"))
  |> u.join(inner_join())
  // calling joins([]) on a query that already has a join should be a no-op
  |> u.joins([])
  |> u.to_query
  |> to_string
  |> birdie.snap("update_joins_empty_preserves_existing_test")
}

pub fn update_joins_empty_on_empty_query_test() {
  u.new()
  |> u.table("owners")
  |> u.set("name" |> u.set_string("Alice"))
  // calling joins([]) on a query with no joins should also be a no-op
  |> u.joins([])
  |> u.to_query
  |> to_string
  |> birdie.snap("update_joins_empty_on_empty_query_test")
}
