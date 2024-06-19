import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/param as p
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as s
import cake/query/where as w
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

fn fragment_query() {
  s.new_from(f.table("cats"))
  |> s.where(
    w.fragment_value(frgmt.literal("LOWER(cats.name)"))
    |> w.eq(
      w.fragment_value(
        frgmt.prepared("LOWER(" <> frgmt.placeholder <> ")", [p.string("Clara")]),
      ),
    ),
  )
  |> s.to_query
}

pub fn fragment_test() {
  fragment_query()
  |> to_string
  |> birdie.snap("fragment_test")
}

pub fn fragment_prepared_statement_test() {
  let pgo = fragment_query() |> postgres_adapter.to_prepared_statement
  let lit = fragment_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("fragment_prepared_statement_test")
}

pub fn fragment_execution_result_test() {
  let pgo = fragment_query() |> postgres_test_helper.setup_and_run
  let lit = fragment_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("fragment_execution_result_test")
}
