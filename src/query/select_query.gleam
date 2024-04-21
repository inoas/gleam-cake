import fragment/order_by_direction.{type OrderByDirectionFragment}
import gleam/list

// List of SQL parts that will be used to build a select query.
pub type SelectQuery {
  SelectQuery(
    // comment: String,
    // modifier: String,
    // with: String,
    select: List(String),
    // distinct: String,
    from: String,
    // join: String,
    where: List(String),
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

pub fn new(from from: String, select select: List(String)) -> SelectQuery {
  SelectQuery(
    select: select,
    from: from,
    where: [],
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn new_from(from from: String) -> SelectQuery {
  SelectQuery(
    select: [],
    from: from,
    where: [],
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn new_select(select select: List(String)) -> SelectQuery {
  SelectQuery(
    select: select,
    from: "",
    where: [],
    order_by: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— FROM ———————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn set_from(query qry: SelectQuery, from from: String) -> SelectQuery {
  SelectQuery(..qry, from: from)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— SELECT —————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn select(
  query qry: SelectQuery,
  select select: List(String),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, select))
}

pub fn select_replace(
  query qry: SelectQuery,
  select select: List(String),
) -> SelectQuery {
  SelectQuery(..qry, select: select)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— WHERE ——————————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn where(query qry: SelectQuery, where where: List(String)) -> SelectQuery {
  SelectQuery(..qry, where: list.append(qry.where, where))
}

pub fn where_replace(
  query qry: SelectQuery,
  where where: List(String),
) -> SelectQuery {
  SelectQuery(..qry, where: where)
}

// —————————————————————————————————————————————————————————————————————————— //
// ———— ORDER BY ———————————————————————————————————————————————————————————— //
// —————————————————————————————————————————————————————————————————————————— //

pub fn order_asc(query qry: SelectQuery, by ordb: String) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.Asc), True)
}

pub fn order_asc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.AscNullsFirst), True)
}

pub fn order_asc_replace(query qry: SelectQuery, by ordb: String) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.Asc), False)
}

pub fn order_asc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.AscNullsFirst), False)
}

pub fn order_desc(query qry: SelectQuery, by ordb: String) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.Desc), True)
}

pub fn order_desc_nulls_first(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.DescNullsFirst), True)
}

pub fn order_desc_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.Desc), False)
}

pub fn order_desc_nulls_first_replace(
  query qry: SelectQuery,
  by ordb: String,
) -> SelectQuery {
  do_order_by(qry, #(ordb, order_by_direction.DescNullsFirst), False)
}

pub fn order(
  query qry: SelectQuery,
  by ordb: String,
  direction dir: OrderByDirectionFragment,
) -> SelectQuery {
  do_order_by(qry, #(ordb, dir), True)
}

pub fn order_replace(
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

pub fn set_limit(qry: SelectQuery, limit lmt: Int) -> SelectQuery {
  case lmt >= 0 {
    True -> SelectQuery(..qry, limit: lmt)
    // TODO: Add warning, negative limit is ignored
    False -> SelectQuery(..qry, limit: -1)
  }
}

pub fn set_limit_and_offset(
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
