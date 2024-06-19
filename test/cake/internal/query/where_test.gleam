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
  s.new_from(f.table("cats"))
  |> s.where(
    sut.or([
      sut.col("age") |> sut.lt(sut.int(100)),
      sut.col("age") |> sut.lte(sut.int(99)),
      sut.col("age") |> sut.eq(sut.int(50)),
      sut.col("age") |> sut.lt(sut.int(10)),
      sut.col("age") |> sut.lte(sut.int(9)),
    ]),
  )
  |> s.where(sut.fragment(frgmt.literal("1 = 1")))
  |> s.where(
    sut.or([
      sut.col("name") |> sut.eq(sut.string("Karl")),
      sut.col("name") |> sut.eq(sut.string("Clara")),
    ]),
  )
  |> s.where(
    sut.or([
      sut.col("is_wild") |> sut.is_false,
      sut.col("is_wild") |> sut.is_true,
      sut.col("is_wild") |> sut.is_bool(False),
      sut.col("is_wild") |> sut.is_bool(True),
      sut.col("is_wild") |> sut.is_not_bool(False),
      sut.col("is_wild") |> sut.is_not_bool(True),
      sut.col("is_wild") |> sut.is_null,
      sut.col("is_wild") |> sut.is_not_null,
    ]),
  )
  |> s.where(
    sut.or([
      sut.not(sut.col("rating") |> sut.gt(sut.float(0.0))),
      sut.not(sut.col("rating") |> sut.is_null),
    ]),
  )
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

fn where_any_query() {
  s.new_from(f.table("cats"))
  |> s.where(
    sut.col("owner_id")
    |> sut.lt_any_query(
      s.new_from(f.table("dogs"))
      |> s.selects([s.col("owner_id")])
      |> s.limit(1)
      |> s.to_query,
    ),
  )
  |> s.to_query
}

pub fn where_any_test() {
  where_any_query()
  |> to_string
  |> birdie.snap("where_any_test")
}

pub fn where_any_prepared_statement_test() {
  let pgo = where_any_query() |> postgres_adapter.to_prepared_statement
  let lit = where_any_query() |> sqlite_adapter.to_prepared_statement

  #(pgo, lit)
  |> to_string
  |> birdie.snap("where_any_prepared_statement_test")
}
// pub fn where_any_execution_result_test() {
//   let pgo = where_any_query() |> postgres_test_helper.setup_and_run
//   let lit = where_any_query() |> sqlite_test_helper.setup_and_run

//   #(pgo, lit)
//   |> to_string
//   |> birdie.snap("where_any_execution_result_test")
// }
