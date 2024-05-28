import birdie
import cake/internal/query as q
import cake/param as p
import cake/query/combined as c
import cake/query/fragment as frgmt
import cake/query/from as f
import cake/query/join as j
import cake/query/select as s
import cake/query/where as w
import gleam/function.{tap as tap}
import pprint.{format as to_string}

pub fn query_fragment_snap_test() {
  let cats_query =
    f.table(name: "cats")
    |> s.new_from()
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("cats_query")
      v
    })
  cats_query
  |> s.where(
    w.col("name")
    |> w.eq(
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
    ),
  )
  |> tap(fn(v) {
    v |> to_string |> birdie.snap("cats_query_2")
    v
  })
}

pub fn query_select_snap_test() {
  let cats_sub_query =
    f.table(name: "cats")
    |> s.new_from()
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("cats_sub_query")
      v
    })

  let dogs_sub_query =
    f.table(name: "dogs")
    |> s.new_from()
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("dogs_sub_query")
      v
    })

  let cats_t = q.qualified_identifier("cats")
  let owners_t = q.qualified_identifier("owners")

  let where =
    w.or([
      w.col(cats_t("age")) |> w.eq(w.int(10)),
      w.col(cats_t("name")) |> w.eq(w.string("foo")),
      w.col(cats_t("name")) |> w.eq(w.string("foo")),
      w.col(cats_t("age")) |> w.in([w.int(1), w.int(2)]),
    ])
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("where")
      v
    })

  cats_sub_query
  |> s.to_query
  |> f.sub_query(alias: "cats")
  |> s.new_from
  |> s.selects([
    s.col(cats_t("name")),
    s.col(cats_t("age")),
    s.col(owners_t("name")) |> s.alias("owner_name"),
  ])
  |> s.where(where)
  |> s.order_asc(cats_t("name"))
  |> s.order_replace(by: cats_t("age"), direction: s.Asc)
  |> s.set_limit(1)
  |> s.set_limit_and_offset(1, 0)
  |> s.joins([
    j.inner(
      with: j.table("owners"),
      alias: "owners",
      on: w.or([
        w.col(owners_t("id")) |> w.eq(w.col(cats_t("owner_id"))),
        w.col(owners_t("id")) |> w.lt(w.int(20)),
        w.col(owners_t("id")) |> w.is_not_null(),
      ]),
    ),
    j.cross(with: j.sub_query(s.to_query(dogs_sub_query)), alias: "dogs"),
  ])
  |> tap(fn(v) {
    v |> to_string |> birdie.snap("composed")
    v
  })
}

pub fn query_combined_snap_test() {
  let base_select_query =
    f.table(name: "cats")
    |> s.new_from()
    |> s.selects([s.col("name"), s.col("age")])
    |> tap(fn(v) {
      v
      |> to_string
      |> birdie.snap("base_select_query")
      v
    })

  let select_query_a =
    base_select_query
    |> s.where(
      w.or([
        w.col("age") |> w.lte(w.int(4)),
        w.col("name") |> w.like(pattern: "%ara%"),
        // w.similar("name", to: "%(y|a)%"), // NOTICE: SIMILAR TO does not run on Sqlite
      ]),
    )
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("select_query_a")
      v
    })

  let where_b =
    w.not(w.is_not_bool(w.col("is_wild"), False))
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("where_b")
      v
    })

  let select_query_b =
    base_select_query
    |> s.where(w.col("age") |> w.gte(w.int(7)))
    |> s.order_asc(by: "will_be_removed")
    |> s.where(where_b)
    |> tap(fn(v) {
      v |> to_string |> birdie.snap("select_query_b")
      v
    })

  [select_query_a, select_query_b]
  |> c.union_all()
  |> c.set_limit(1)
  |> c.order_replace(by: "age", direction: c.Asc)
  |> c.to_query
  |> tap(fn(v) {
    v
    |> to_string
    |> birdie.snap("combined_query")
    v
  })
}
