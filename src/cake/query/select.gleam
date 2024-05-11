import cake/internal/query.{
  type FromPart, type JoinPart, type SelectPart, type SelectQuery,
  type WherePart, NoEpilogPart, NoFromPart, NoLimitOffset, NoWherePart,
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

// ▒▒▒ SELECT ▒▒▒

pub fn select(
  select_query qry: SelectQuery,
  select_parts slct_prts: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: list.append(qry.select, slct_prts))
}

pub fn select_replace(
  select_query qry: SelectQuery,
  select_parts slct_prts: List(SelectPart),
) -> SelectQuery {
  SelectQuery(..qry, select: slct_prts)
}

pub fn get_select(select_query qry: SelectQuery) -> List(SelectPart) {
  qry.select
}

// ▒▒▒ WHERE ▒▒▒

pub fn set_where(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  SelectQuery(..qry, where: whr)
}

pub fn and_where(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  let new_where = query.AndWhere([qry.where, ..[whr]])
  SelectQuery(..qry, where: new_where)
}

pub fn or_where(
  select_query qry: SelectQuery,
  where whr: WherePart,
) -> SelectQuery {
  let new_where = query.OrWhere([qry.where, ..[whr]])
  SelectQuery(..qry, where: new_where)
}

// TODO: pub fn xor_where

pub fn get_where(select_query qry: SelectQuery) -> WherePart {
  qry.where
}

// ▒▒▒ JOIN ▒▒▒

pub fn set_join(
  select_query qry: SelectQuery,
  join_parts prts: List(JoinPart),
) -> SelectQuery {
  SelectQuery(..qry, join: prts)
}

pub fn add_join(
  select_query qry: SelectQuery,
  join_parts prts: JoinPart,
) -> SelectQuery {
  let new_joins = [prts, ..qry.join]
  SelectQuery(..qry, join: new_joins)
}

pub fn get_joins(select_query qry: SelectQuery) -> List(JoinPart) {
  qry.join
}
