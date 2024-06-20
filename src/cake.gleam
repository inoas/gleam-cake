//// *Cake* is an SQL query building library for RDBMS:
////
//// - PostgreSQL
//// - Sqlite
//// - MariaDB / MySQL
////
//// For examples see the tests.
////

import gleam/io

/// As a library *Cake* cannot be invoked directly in a meaningful way.
///
pub fn main() {
  {
    "\n"
    <> "cake is a query building library and cannot be invoked directly."
    <> "\n"
    <> "For demos see the tests."
  }
  |> io.println
}
// TODO v3:
// pub fn table_exists(connection conn: Connection, table_name tbl_nm: String) -> Boolean {
//   todo
// }
//
// pub fn tables_exists(connection conn: Connection, table_names tbl_nms: List(String)) -> List(#(String, Boolean)) {
//   todo
// }
//
// pub fn view_exists(connection conn: Connection, view_name vw_nm: String) -> Boolean {
//   todo
// }
//
// pub fn views_exists(connection conn: Connection, view_names vw_nms: List(String)) -> List(#(String, Boolean)) {
//   todo
// }
