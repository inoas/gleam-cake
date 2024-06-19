//// Functions to build the `FROM` clause
//// of an SQL query.
////

import cake/internal/query.{type From, type Query, FromSubQuery, FromTable}

pub fn table(name tbl_nm: String) -> From {
  tbl_nm |> FromTable
}

pub fn sub_query(sub_query qry: Query, alias als: String) -> From {
  qry |> FromSubQuery(alias: als)
}
