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
    order: List(String),
    limit: Int,
    offset: Int,
    // epilog: String,
    flags: List(#(String, String)),
  )
}

pub fn new(from from: String, select select: List(String)) -> SelectQuery {
  SelectQuery(
    select: select,
    from: from,
    where: [],
    order: [],
    limit: -1,
    offset: -1,
    flags: [],
  )
}

pub fn from(query: SelectQuery, from: String) -> SelectQuery {
  SelectQuery(..query, from: from)
}

pub fn select(
  query: SelectQuery,
  select: List(String),
  append: Bool,
) -> SelectQuery {
  case append {
    True -> SelectQuery(..query, select: list.append(query.select, select))
    False -> SelectQuery(..query, select: select)
  }
}

pub fn where(
  query: SelectQuery,
  where: List(String),
  append: Bool,
) -> SelectQuery {
  case append {
    True -> SelectQuery(..query, where: list.append(query.where, where))
    False -> SelectQuery(..query, where: where)
  }
}

pub fn order(
  query: SelectQuery,
  order: List(String),
  append: Bool,
) -> SelectQuery {
  case append {
    True -> SelectQuery(..query, order: list.append(query.order, order))
    False -> SelectQuery(..query, order: order)
  }
}

pub fn limit(query: SelectQuery, limit: Int) -> SelectQuery {
  case limit < 0 {
    True -> SelectQuery(..query, limit: -1)
    False -> SelectQuery(..query, limit: limit)
  }
}

pub fn offset(query: SelectQuery, offset: Int) -> SelectQuery {
  case offset < 0 {
    True -> SelectQuery(..query, offset: -1)
    False -> SelectQuery(..query, offset: offset)
  }
}
