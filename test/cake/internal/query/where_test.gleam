import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as s
import cake/query/where as sut
import pprint.{format as to_string}
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper

fn where_query() {
  s.from(f.table("cats"))
  |> s.where(sut.col("age") |> sut.eq(sut.int(10)))
  |> s.where(sut.fragment(frgmt.literal("1 = 1")))
  |> s.where(sut.string("Hello") |> sut.eq(sut.col("name")))
  |> s.where(
    sut.or([
      sut.col("is_wild") |> sut.is_false,
      sut.col("is_wild") |> sut.is_true,
    ]),
  )
  |> s.where(sut.col("age") |> sut.gte(sut.int(0)))
  |> s.where(sut.float(1.0) |> sut.eq(sut.col("rating")))
  |> s.to_query
}

pub fn where_test() {
  where_query()
  |> to_string
  |> birdie.snap("where_test")
}

pub fn where_prepared_statement_test() {
  let pgo = where_query() |> postgres_adapter.to_prepared_statement
  let lit = where_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("where_prepared_statement_test")
}

pub fn where_execution_result_test() {
  let pgo = where_query() |> postgres_test_helper.setup_and_run
  let lit = where_query() |> sqlite_test_helper.setup_and_run

  #(pgo, lit)
  |> to_string
  |> birdie.snap("where_execution_result_test")
}
