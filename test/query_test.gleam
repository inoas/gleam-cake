import cake/internal/query as q
import cake/param as p
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/select as s
import cake/query/where as w
import cake_test.{assert_snap}

pub fn query_fragment_snap_test() {
  let test_function_name = "query_fragment_snap_test"

  let cats_query =
    f.table(name: "cats")
    |> s.new_from()
    |> assert_snap(title: test_function_name <> "cats_query")

  cats_query
  |> s.where(w.eq(
    w.col("name"),
    w.fragment(
      frgmt.prepared(
        "LOWER("
          <> frgmt.placeholder
          <> ") OR name = LOWER("
          <> frgmt.placeholder
          <> ")",
        [p.string("Timmy"), p.string("Jimmy")],
      ),
    ),
  ))
  |> assert_snap(title: test_function_name <> "cats_where_fragment_query")
}

pub fn query_select_snap_test() {
  let test_function_name = "query_select_snap_test_"

  let cats_sub_query =
    f.table(name: "cats")
    |> s.new_from()
    |> assert_snap(title: test_function_name <> "cats_sub_query")

  let dogs_sub_query =
    f.table(name: "dogs")
    |> s.new_from()
    |> assert_snap(title: test_function_name <> "dogs_sub_query")

  let cats_t = q.qualified_identifier("cats")
  let owners_t = q.qualified_identifier("owners")

  let where =
    w.or([
      w.col(cats_t("age")) |> w.eq(w.int(10)),
      w.col(cats_t("name")) |> w.eq(w.string("foo")),
      w.col(cats_t("name")) |> w.eq(w.string("foo")),
      w.col(cats_t("age")) |> w.in([w.int(1), w.int(2)]),
    ])
    |> assert_snap(title: test_function_name <> "where")

  s.new_from(f.sub_query(q.query_select_wrap(cats_sub_query), alias: "cats"))
  |> s.select([
    q.select_part_from(cats_t("name")),
    q.select_part_from(cats_t("age")),
    // TODO: this is bad:
    q.select_part_from("owners.name AS owner_name"),
  ])
  |> s.where(where)
  |> q.select_query_order_asc(cats_t("name"))
  |> q.select_query_order_replace(by: cats_t("age"), direction: q.Asc)
  |> q.select_query_set_limit(1)
  |> q.select_query_set_limit_and_offset(1, 0)
  |> s.joins([
    q.InnerJoin(
      with: q.JoinTable("owners"),
      alias: "owners",
      on: w.or([
        w.col(owners_t("id")) |> w.eq(w.col(cats_t("owner_id"))),
        w.col(owners_t("id")) |> w.lt(w.int(20)),
        w.col(owners_t("id")) |> w.is_not_null(),
      ]),
    ),
    q.CrossJoin(
      with: q.JoinSubQuery(q.query_select_wrap(dogs_sub_query)),
      alias: "dogs",
    ),
  ])
  |> assert_snap(title: test_function_name <> "composed")
}

pub fn query_combined_snap_test() {
  let test_function_name = "query_combined_snap_test_"

  let base_select_query =
    f.table(name: "cats")
    |> s.new_from()
    |> s.select([q.select_part_from("name"), q.select_part_from("age")])
    |> assert_snap(title: test_function_name <> "base_select_query")

  let select_query_a =
    base_select_query
    |> s.where(
      w.or([
        w.col("age") |> w.lte(w.int(4)),
        w.col("name") |> w.like(pattern: "%ara%"),
        // w.similar("name", to: "%(y|a)%"), // NOTICE: Does not run on Sqlite
      ]),
    )
    |> assert_snap(title: test_function_name <> "select_query_a")

  let where_b =
    w.not(w.is_not_bool(w.col("is_wild"), False))
    |> assert_snap(title: test_function_name <> "where_b")

  let select_query_b =
    base_select_query
    |> s.where(w.gte(w.col("age"), w.int(7)))
    |> q.select_query_order_asc(by: "will_be_removed")
    |> s.where(where_b)
    |> assert_snap(title: test_function_name <> "select_query_b")

  q.combined_union_all_query_new([select_query_a, select_query_b])
  |> q.combined_query_set_limit(1)
  |> q.combined_query_order_replace(by: "age", direction: q.Asc)
  |> q.query_combined_wrap
  |> assert_snap(title: test_function_name <> "combined_query")
}
