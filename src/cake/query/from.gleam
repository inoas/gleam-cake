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
// TODO v3:
// pub fn table_exists(connection conn: Connection, table_name tbl_nm: String) -> Boolean {
//   todo
// }

// TODO v3:
// pub fn tables_exists(connection conn: Connection, table_names tbl_nms: List(String)) -> List(#(String, Boolean)) {
//   todo
// }
