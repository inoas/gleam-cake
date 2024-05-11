import cake/internal/query.{type FromPart, type Query, FromSubQuery, FromTable}

pub fn table(name tbl_nm: String) -> FromPart {
  FromTable(name: tbl_nm)
}

pub fn sub_query(sub_query qry: Query, alias als: String) -> FromPart {
  FromSubQuery(sub_query: qry, alias: als)
}
