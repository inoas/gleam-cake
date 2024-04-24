import cake/fragment/from_fragment.{type FromFragment, NoFromFragment}
import cake/fragment/order_by_direction_fragment.{type OrderByDirectionFragment}
import cake/fragment/select_fragment.{type SelectFragment}
import cake/fragment/where_fragment.{type WhereFragment, NoWhereFragment}
import gleam/list

// List of SQL parts that will be used to build a select query.
pub type SelectQuery {
  SelectQuery(
    from: FromFragment,
    // comment: String,
    // modifier: String,
    // with: String,
    select: List(SelectFragment),
    // distinct: String,
    // join: String,
    where: WhereFragment,
    // group_by: String,
    // having: String,
    // window: String,
    order_by: List(#(String, OrderByDirectionFragment)),
    limit: Int,
    offset: Int,
    // epilog: String,
    flags: List(#(String, String)),
  )
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— NEW ————————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_new(
  from from: FromFragment,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(
    from: from,
    select: select,
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn select_query_new_from(from from: FromFragment) -> SelectQuery {
  SelectQuery(
    from: from,
    select: [],
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn select_query_new_select(
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(
    from: NoFromFragment,
    select: select,
    where: NoWhereFragment,
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— FROM ———————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_set_from(
  query qry: SelectQuery,
  from from: FromFragment,
) -> SelectQuery {
  SelectQuery(..qry, from: from)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SELECT —————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_select(
  query qry: SelectQuery,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, select))
}

pub fn select_query_select_replace(
  query qry: SelectQuery,
  select select: List(SelectFragment),
) -> SelectQuery {
  SelectQuery(..qry, select: select)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— WHERE ——————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_set_where(
  query qry: SelectQuery,
  where where: WhereFragment,
) -> SelectQuery {
  SelectQuery(..qry, where: where)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— ORDER BY ———————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_order_asc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.Asc), True)
}

pub fn select_query_order_asc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.AscNullsFirst), True)
}

pub fn select_query_order_asc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.Asc), False)
}

pub fn select_query_order_asc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.AscNullsFirst), False)
}

pub fn select_query_order_desc(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.Desc), True)
}

pub fn select_query_order_desc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.DescNullsFirst), True)
}

pub fn select_query_order_desc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.Desc), False)
}

pub fn select_query_order_desc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction_fragment.DescNullsFirst), False)
}

pub fn select_query_order(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionFragment,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), True)
}

pub fn select_query_order_replace(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionFragment,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), False)
}

fn do_order_by(
  query qry: SelectQuery,
  by ordb: #(String, OrderByDirectionFragment),
  append append: Bool,
) -> SelectQuery {
  case append {
    True -> SelectQuery(..qry, order_by: list.append(qry.order_by, [ordb]))
    False -> SelectQuery(..qry, order_by: [ordb])
  }
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— LIMIT & OFFSET —————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select_query_set_limit(qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  case lmt >= 0 {
    True -> SelectQuery(..qry, limit: lmt)
    // TODO: Add warning, negative limit is ignored
    False -> SelectQuery(..qry, limit: -1)
  }
}

pub fn select_query_set_limit_and_offset(
  query qry: SelectQuery,
  limit lmt: Int,
  offset offst: Int,
) -> SelectQuery {
  case lmt >= 0, offst >= 0 {
    True, True -> SelectQuery(..qry, limit: lmt, offset: offst)
    // TODO: Add debug warning, negative limit is ignored as well as any offset then
    True, False -> SelectQuery(..qry, limit: lmt, offset: -1)
    // TODO: Add debug negative offset is ignored
    False, _ -> SelectQuery(..qry, limit: -1, offset: -1)
  }
}
