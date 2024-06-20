import gleam/io

pub fn main() {
  {
    "\n"
    <> "cake is a query building library and cannot be invoked directly."
    <> "\n"
    <> "For demos see cake/internal/examples/"
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
