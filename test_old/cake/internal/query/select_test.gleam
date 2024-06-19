import birdie
import cake/adapter/postgres_adapter
import cake/adapter/sqlite_adapter
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as sut
import pprint.{format as to_string}

fn selects_query() {
  f.table(name: "cats")
  |> sut.new_from
  |> sut.select([
    sut.col("name"),
    sut.bool(True),
    sut.float(1.0),
    sut.int(1),
    sut.string("hello"),
    sut.fragment(frgmt.literal("count(*)")),
    sut.alias(sut.col("name"), "also_name"),
  ])
  |> sut.to_query
}

pub fn selects_test() {
  let expected_pgo = selects_query() |> postgres_adapter.to_prepared_statement
  let expected_sql = selects_query() |> sqlite_adapter.to_prepared_statement

  #(expected_pgo, expected_sql) |> to_string |> birdie.snap("selects_test")
}
