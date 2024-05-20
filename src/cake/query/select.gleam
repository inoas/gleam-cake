import cake/internal/query.{
  type FromPart, type JoinPart, type Query, type SelectPart, type SelectQuery,
  type WherePart, NoEpilogPart, NoFromPart, NoLimitOffset, NoWherePart, Select,
  SelectQuery,
}
import gleam/list

// ▒▒▒ NEW ▒▒▒

pub fn new(from frm: FromPart, select slct: List(SelectPart)) -> SelectQuery {
  SelectQuery(
    select: slct,
    from: frm,
    where: NoWherePart,
    join: [],
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
    // kind: RegularSelect,
  )
}

pub fn new_from(from frm: FromPart) -> SelectQuery {
  SelectQuery(
    select: [],
    from: frm,
    join: [],
    where: NoWherePart,
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
    // kind: RegularSelect,
  )
}

pub fn new_select(select slct: List(SelectPart)) -> SelectQuery {
  SelectQuery(
    select: slct,
    from: NoFromPart,
    where: NoWherePart,
    join: [],
    order_by: [],
    limit_offset: NoLimitOffset,
    epilog: NoEpilogPart,
    // kind: RegularSelect,
  )
}

// ▒▒▒ FROM ▒▒▒

pub fn set_from(
  select_query qry: SelectQuery,
  from frm: FromPart,
) -> SelectQuery {
  SelectQuery(..qry, from: frm)
}

pub fn get_from(select_query qry: SelectQuery) -> FromPart {
  qry.from
}

// ▒▒▒ SELECT ▒▒▒

pub fn select(
  select_query qry: SelectQuery,
  select_parts prts: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, prts))
}

pub fn select_replace(
  select_query qry: SelectQuery,
  select_parts prts: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: prts)
}

pub fn get_select(select_query qry: SelectQuery) -> List(SelectPart) {
  qry.select
}

// ▒▒▒ WHERE ▒▒▒

pub fn where(select_query qry: SelectQuery, where whr: WherePart) -> SelectQuery {
  let new_where = query.AndWhere([qry.where, whr])
  SelectQuery(..qry, where: new_where)
}

pub fn or_where(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  let new_where = query.OrWhere([qry.where, whr])
  SelectQuery(..qry, where: new_where)
}

pub fn where_replace(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

// TODO: pub fn xor_where

pub fn get_where(select_query qry: SelectQuery) -> WherePart {
  qry.where
}

// ▒▒▒ JOIN ▒▒▒

pub fn join(
  select_query qry: SelectQuery,
  join_part prt: JoinPart,
) -> SelectQuery {
  SelectQuery(..qry, join: list.append(qry.join, [prt]))
}

pub fn joins(
  select_query qry: SelectQuery,
  join_parts prts: List(JoinPart),
) -> SelectQuery {
  SelectQuery(..qry, join: list.append(qry.join, prts))
}

pub fn join_replace(
  select_query qry: SelectQuery,
  join_part prt: JoinPart,
) -> SelectQuery {
  SelectQuery(..qry, join: [prt])
}

pub fn joins_replace(
  select_query qry: SelectQuery,
  join_parts prts: List(JoinPart),
) -> SelectQuery {
  SelectQuery(..qry, join: prts)
}

pub fn get_joins(select_query qry: SelectQuery) -> List(JoinPart) {
  qry.join
}

pub fn to_query(select_query qry: SelectQuery) -> Query {
  qry |> Select()
}
