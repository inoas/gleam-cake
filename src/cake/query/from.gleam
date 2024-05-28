import cake/internal/query.{type From, type Query, FromSubQuery, FromTable}

pub fn table(name tbl_nm: String) -> From {
  FromTable(name: tbl_nm)
}

pub fn sub_query(sub_query qry: Query, alias als: String) -> From {
  FromSubQuery(sub_query: qry, alias: als)
}
