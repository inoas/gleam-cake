import cake/internal/prepared_statement.{type PreparedStatement}
import cake/param.{type Param}
import gleam/int
import gleam/list
import gleam/order
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Query                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Query {
  SelectQuery(query: Select)
  CombinedQuery(query: Combined)
}

pub fn builder_new(
  query qry: Query,
  prepared_statement_prefix prp_stm_prfx: String,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new
  |> builder_apply(qry)
}

fn builder_apply(
  prepared_statement prp_stm: PreparedStatement,
  query qry: Query,
) -> PreparedStatement {
  case qry {
    SelectQuery(query: qry) -> prp_stm |> select_builder(qry)
    CombinedQuery(query: qry) -> prp_stm |> combined_builder(qry)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Combined (UNION, UNION ALL, etc)                                         │
// └───────────────────────────────────────────────────────────────────────────┘

fn combined_builder(
  prepared_statement prp_stm: PreparedStatement,
  combined_query qry: Combined,
) -> PreparedStatement {
  prp_stm
  |> combined_clause_apply(qry)
  |> order_by_clause_apply(qry.order_by)
  |> limit_offset_clause_apply(qry.limit_offset)
  |> epilog_apply(qry.epilog)
}

pub fn combined_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  combined_query qry: Combined,
) -> PreparedStatement {
  let sql_command = case qry.kind {
    Union -> "UNION"
    UnionAll -> "UNION ALL"
    Except -> "EXCEPT"
    ExceptAll -> "EXCEPT ALL"
    Intersect -> "INTERSECT"
    IntersectAll -> "INTERSECT ALL"
  }

  qry.queries
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, qry: Select) -> PreparedStatement {
      case new_prp_stm == prp_stm {
        True -> new_prp_stm |> select_builder(qry)
        False -> {
          new_prp_stm
          |> prepared_statement.append_sql(" " <> sql_command <> " ")
          |> select_builder(qry)
        }
      }
    },
  )
}

pub type Combined {
  Combined(
    kind: CombinedQueryKind,
    // TODO: if single list item, unwrap Combined to Select and warn user // v2
    queries: List(Select),
    // TODO: split up and wrap
    // limit: Limit // v0
    // offset: Offset // v0
    limit_offset: LimitOffset,
    order_by: OrderBy,
    // Epilog allows you to append raw SQL to the end of queries.
    // One should NEVER put raw user data into the epilog.
    epilog: Epilog,
  )
}

pub type CombinedQueryKind {
  Union
  UnionAll
  Except
  // NOTICE: ExceptAll Does not work on SQLite, TODO: add to query builder validator
  ExceptAll
  Intersect
  // NOTICE: IntersectAll Does not work on SQLite, TODO: add to query builder validator
  IntersectAll
}

// TODO: Also allow nested combined in combined_get_queries
// from any nested SELECT
pub fn combined_query_new(
  kind knd: CombinedQueryKind,
  queries qrys: List(Select),
) -> Combined {
  qrys
  // NOTICE: `ORDER BY` is not allowed for queries,
  // that are part of combined queries:
  |> combined_query_remove_order_by_clause
  |> Combined(
    kind: knd,
    queries: _,
    limit_offset: NoLimitNoOffset,
    order_by: NoOrderBy,
    epilog: NoEpilog,
  )
}

fn combined_query_remove_order_by_clause(
  queries qrys: List(Select),
) -> List(Select) {
  // TODO: Add notice that order_by was dropped if it existed before
  // TODO: Would be very useful if we could inject a logging function here
  // TODO: Would be very cool if that code part would be eliminated
  //       depending on the environment.
  qrys
  |> list.map(fn(qry: Select) -> Select { Select(..qry, order_by: NoOrderBy) })
}

pub fn combined_get_queries(combined_query qry: Combined) -> List(Select) {
  qry.queries
}

pub fn combined_order_by(
  query qry: Combined,
  by ordb: OrderBy,
  append appnd: Bool,
) -> Combined {
  case appnd {
    True -> Combined(..qry, order_by: order_by_append(qry.order_by, ordb))
    False -> Combined(..qry, order_by: ordb)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Select                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

fn select_builder(
  prepared_statement prp_stm: PreparedStatement,
  select_query qry: Select,
) -> PreparedStatement {
  prp_stm
  |> select_clause_apply(qry.selects)
  |> from_clause_apply(qry.from)
  |> join_clause_apply(qry.joins)
  |> where_clause_apply(qry.where)
  |> order_by_clause_apply(qry.order_by)
  |> limit_offset_clause_apply(qry.limit_offset)
}

pub type Select {
  Select(
    // with: String, // v2
    // with_recursive: String, ? // v2
    // TODO: singular field:
    selects: Selects,
    // modifier: String, // v1
    // distinct: String, // v1
    // window: String, // v2
    from: From,
    // TODO: singular field:
    joins: Joins,
    where: Where,
    group_by: GroupBy,
    having: Where,
    order_by: OrderBy,
    // TODO: split up and wrap
    // limit: Limit // v0
    // offset: Offset // v0
    limit_offset: LimitOffset,
    epilog: Epilog,
    // comment: String, // v2
    // values: String, // ?
  )
}

pub fn select_order_by(
  select_query qry: Select,
  by ordb: OrderBy,
  append appnd: Bool,
) -> Select {
  case appnd {
    True -> Select(..qry, order_by: order_by_append(qry.order_by, ordb))
    False -> Select(..qry, order_by: ordb)
  }
}

fn order_by_append(query_ordb: OrderBy, new_ordb: OrderBy) -> OrderBy {
  case query_ordb {
    NoOrderBy -> new_ordb
    OrderBy(qry_ordb_items) -> {
      let new_ordb_items = case new_ordb {
        NoOrderBy -> []
        OrderBy(new_ordb) -> new_ordb
      }
      let new_ordb_item = case qry_ordb_items {
        [] -> new_ordb_items
        _ -> qry_ordb_items |> list.append(new_ordb_items)
      }
      case new_ordb_item {
        [] -> NoOrderBy
        _ -> OrderBy(new_ordb_item)
      }
    }
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Selects                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Selects {
  NoSelects
  Selects(List(SelectValue))
}

pub type SelectValue {
  SelectColumn(column: String)
  SelectParam(param: Param)
  SelectFragment(fragment: Fragment)
  SelectAlias(value: SelectValue, alias: String)
}

fn select_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  selects slcts: Selects,
) -> PreparedStatement {
  case slcts {
    NoSelects -> prp_stm |> prepared_statement.append_sql("SELECT *")
    Selects(slct_vs) -> {
      case slct_vs {
        [] -> prp_stm
        vs -> {
          let prp_stm = prp_stm |> prepared_statement.append_sql("SELECT ")
          vs
          |> list.fold(
            prp_stm,
            fn(new_prp_stm: PreparedStatement, v: SelectValue) -> PreparedStatement {
              case new_prp_stm == prp_stm {
                True -> new_prp_stm |> select_value_apply(v)
                False ->
                  new_prp_stm
                  |> prepared_statement.append_sql(", ")
                  |> select_value_apply(v)
              }
            },
          )
        }
      }
    }
  }
}

fn select_value_apply(
  prepared_statement prp_stm: PreparedStatement,
  value v: SelectValue,
) -> PreparedStatement {
  case v {
    SelectColumn(col) -> prp_stm |> prepared_statement.append_sql(col)
    SelectParam(param) -> prp_stm |> prepared_statement.append_param(param)
    SelectFragment(frgmnt) -> prp_stm |> fragment_apply(frgmnt)
    SelectAlias(v, als) ->
      prp_stm
      |> select_value_apply(v)
      |> prepared_statement.append_sql(" AS " <> als)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  From                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

pub type From {
  NoFrom
  // TODO: Check if the table or view does indeed exist
  FromTable(name: String)
  FromSubQuery(sub_query: Query, alias: String)
}

fn from_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  part prt: From,
) -> PreparedStatement {
  case prt {
    NoFrom -> prp_stm
    FromTable(tbl) -> prp_stm |> prepared_statement.append_sql(" FROM " <> tbl)
    FromSubQuery(qry, als) ->
      prp_stm
      |> prepared_statement.append_sql(" FROM (")
      |> builder_apply(qry)
      |> prepared_statement.append_sql(") AS " <> als)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Where                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Where {
  NoWhere
  WhereEqual(value_a: WhereValue, value_b: WhereValue)
  WhereLower(value_a: WhereValue, value_b: WhereValue)
  WhereLowerOrEqual(value_a: WhereValue, value_b: WhereValue)
  WhereGreater(value_a: WhereValue, value_b: WhereValue)
  WhereGreaterOrEqual(value_a: WhereValue, value_b: WhereValue)
  WhereUnequal(value_a: WhereValue, value_b: WhereValue)
  WhereIsBool(value: WhereValue, bool: Bool)
  WhereIsNotBool(value: WhereValue, bool: Bool)
  WhereIsNull(value: WhereValue)
  WhereIsNotNull(value: WhereValue)
  WhereLike(value_a: WhereValue, string: String)
  WhereILike(value_a: WhereValue, string: String)
  // NOTICE: Sqlite does not support `SIMILAR TO` / TODO: add to query builder validator
  WhereSimilar(value_a: WhereValue, string: String)
  // TODO: Check if this works with sub queries once WhereValue can also be a
  WhereIn(value_a: WhereValue, values: List(WhereValue))
  WhereBetween(value_a: WhereValue, value_b: WhereValue, value_c: WhereValue)
  AndWhere(parts: List(Where))
  OrWhere(parts: List(Where))
  // TODO: XorWhere(List(Where))
  NotWhere(part: Where)
  // WhereAllOfSubQuery(value: WhereValue, sub_query: Query)
  // WhereAnyOfSubQuery(value: WhereValue, sub_query: Query)
  // WhereExistsInSubQuery(sub_query: Query)
}

pub type WhereValue {
  WhereColumn(column: String)
  WhereParam(param: Param)
  WhereFragment(fragment: Fragment)
  // TODO:
  // WhereSubQuery(sub_query: Query)
  // NOTICE: For some commands, the return value must be scalar:
  // 1 column, 1 row (LIMIT 1)
  // If there are multiple, take the list of select parts
  // and return the last one, if there is none, return NULL
}

fn where_apply(
  prepared_statement prp_stm: PreparedStatement,
  part wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prp_stm
    WhereEqual(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "=", val_b)
    WhereLower(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<", val_b)
    WhereLowerOrEqual(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<=", val_b)
    WhereGreater(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, ">", val_b)
    WhereGreaterOrEqual(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, ">=", val_b)
    WhereUnequal(val_a, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<>", val_b)
    WhereIsBool(val, True) -> prp_stm |> where_apply_literal(val, "IS TRUE")
    WhereIsBool(val, False) -> prp_stm |> where_apply_literal(val, "IS FALSE")
    WhereIsNotBool(val, True) ->
      prp_stm |> where_apply_literal(val, "IS NOT TRUE")
    WhereIsNotBool(val, False) ->
      prp_stm |> where_apply_literal(val, "IS NOT FALSE")
    WhereIsNull(val) -> prp_stm |> where_apply_literal(val, "IS NULL")
    WhereIsNotNull(val) -> prp_stm |> where_apply_literal(val, "IS NOT NULL")
    WhereLike(val, prm) ->
      prp_stm
      |> where_comparison_apply(val, "LIKE", WhereParam(param.StringParam(prm)))
    WhereILike(col, prm) ->
      prp_stm
      |> where_comparison_apply(
        col,
        "ILIKE",
        WhereParam(param.StringParam(prm)),
      )
    WhereSimilar(col, prm) ->
      prp_stm
      |> where_comparison_apply(
        col,
        "SIMILAR TO",
        WhereParam(param.StringParam(prm)),
      )
      |> prepared_statement.append_sql(" ESCAPE '/'")
    AndWhere(whs) -> prp_stm |> where_apply_logical_operator("AND", whs)
    OrWhere(whs) -> prp_stm |> where_apply_logical_operator("OR", whs)
    NotWhere(wh) -> {
      prp_stm
      |> prepared_statement.append_sql("NOT (")
      |> where_apply(wh)
      |> prepared_statement.append_sql(")")
    }
    WhereIn(val, vals) -> prp_stm |> where_apply_value_in_values(val, vals)
    WhereBetween(val_a, val_b, val_c) ->
      prp_stm |> where_between_apply(val_a, val_b, val_c)
  }
}

fn where_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prp_stm
    _ -> prp_stm |> prepared_statement.append_sql(" WHERE ") |> where_apply(wh)
  }
}

fn where_apply_literal(
  prepared_statement prp_stm: PreparedStatement,
  value v: WhereValue,
  literal lt: String,
) {
  case v {
    WhereColumn(col) ->
      prp_stm |> prepared_statement.append_sql(col <> " " <> lt)
    WhereParam(prm) -> {
      let nxt_plchldr = prp_stm |> prepared_statement.next_placeholder

      prp_stm
      |> prepared_statement.append_sql_and_param(nxt_plchldr <> " " <> lt, prm)
    }
    WhereFragment(fragment: frgmt) -> prp_stm |> fragment_apply(frgmt)
  }
}

fn where_comparison_apply(
  prepared_statement prp_stm: PreparedStatement,
  value_a val_a: WhereValue,
  operator oprtr: String,
  value_b val_b: WhereValue,
) {
  case val_a, val_b {
    WhereColumn(col_a), WhereColumn(col_b) ->
      prp_stm
      |> where_apply_string(col_a <> " " <> oprtr <> " " <> col_b)
    WhereColumn(col), WhereParam(prm) ->
      prp_stm
      |> where_apply_string(col <> " " <> oprtr <> " ")
      |> where_apply_param(prm)
    WhereParam(prm), WhereColumn(col) ->
      prp_stm
      |> where_apply_param(prm)
      |> where_apply_string(" " <> oprtr <> " " <> col)
    WhereParam(prm_a), WhereParam(prm_b) ->
      prp_stm
      |> where_apply_param(prm_a)
      |> where_apply_string(" " <> oprtr <> " ")
      |> where_apply_param(prm_b)
    WhereFragment(frgmt), WhereColumn(col) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> where_apply_string(" " <> oprtr <> " " <> col)
    WhereColumn(col), WhereFragment(frgmt) ->
      prp_stm
      |> where_apply_string(col <> " " <> oprtr <> " ")
      |> fragment_apply(frgmt)
    WhereFragment(frgmt), WhereParam(prm) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> where_apply_string(" " <> oprtr <> " ")
      |> where_apply_param(prm)
    WhereParam(prm), WhereFragment(frgmt) ->
      prp_stm
      |> where_apply_param(prm)
      |> where_apply_string(" " <> oprtr <> " ")
      |> fragment_apply(frgmt)
    WhereFragment(frgmt_a), WhereFragment(frgmt_b) ->
      prp_stm
      |> fragment_apply(frgmt_a)
      |> where_apply_string(" " <> oprtr <> " ")
      |> fragment_apply(frgmt_b)
  }
}

fn where_apply_string(
  prepared_statement prp_stm: PreparedStatement,
  string s: String,
) -> PreparedStatement {
  prp_stm |> prepared_statement.append_sql(s)
}

fn where_apply_param(
  prepared_statement prp_stm: PreparedStatement,
  param prm: Param,
) -> PreparedStatement {
  let nxt_plchldr = prp_stm |> prepared_statement.next_placeholder

  prp_stm |> prepared_statement.append_sql_and_param(nxt_plchldr, prm)
}

fn where_apply_logical_operator(
  prepared_statement prp_stm: PreparedStatement,
  operator oprtr: String,
  where whs: List(Where),
) -> PreparedStatement {
  let prp_stm = prp_stm |> prepared_statement.append_sql("(")

  whs
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, wh: Where) -> PreparedStatement {
      case new_prp_stm == prp_stm {
        True -> new_prp_stm |> where_apply(wh)
        False ->
          new_prp_stm
          |> prepared_statement.append_sql(" " <> oprtr <> " ")
          |> where_apply(wh)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_apply_value_in_values(
  prepared_statement prp_stm: PreparedStatement,
  value val: WhereValue,
  parameters prms: List(WhereValue),
) -> PreparedStatement {
  let prp_stm =
    case val {
      WhereColumn(col) -> prp_stm |> prepared_statement.append_sql(col)
      WhereParam(prm) -> {
        let nxt_plchldr_a = prp_stm |> prepared_statement.next_placeholder
        prp_stm |> prepared_statement.append_sql_and_param(nxt_plchldr_a, prm)
      }
      WhereFragment(frgmt) -> prp_stm |> fragment_apply(frgmt)
    }
    |> prepared_statement.append_sql(" IN (")

  prms
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, v: WhereValue) -> PreparedStatement {
      case v {
        WhereColumn(col) ->
          case new_prp_stm == prp_stm {
            True -> prp_stm |> prepared_statement.append_sql(col)
            False -> new_prp_stm |> prepared_statement.append_sql(", " <> col)
          }
        WhereParam(prm) -> {
          case new_prp_stm == prp_stm {
            True -> new_prp_stm |> prepared_statement.next_placeholder
            False -> ", " <> new_prp_stm |> prepared_statement.next_placeholder
          }
          |> prepared_statement.append_sql_and_param(new_prp_stm, _, prm)
        }
        WhereFragment(frgmt) -> prp_stm |> fragment_apply(frgmt)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_between_apply(
  prepared_statement prp_stm: PreparedStatement,
  value_a val_a: WhereValue,
  value_b val_b: WhereValue,
  value_c val_c: WhereValue,
) -> PreparedStatement {
  let prp_stm =
    case val_a {
      WhereColumn(col) -> prp_stm |> prepared_statement.append_sql(col)
      WhereParam(prm) -> {
        let nxt_plchldr = prp_stm |> prepared_statement.next_placeholder
        prp_stm |> prepared_statement.append_sql_and_param(nxt_plchldr, prm)
      }
      WhereFragment(frgmt) -> prp_stm |> fragment_apply(frgmt)
    }
    |> prepared_statement.append_sql(" BETWEEN ")

  let prp_stm =
    case val_b {
      WhereColumn(col) -> prp_stm |> prepared_statement.append_sql(col)
      WhereParam(prm) -> {
        let nxt_plchldr = prp_stm |> prepared_statement.next_placeholder
        prp_stm |> prepared_statement.append_sql_and_param(nxt_plchldr, prm)
      }
      WhereFragment(frgmt) -> prp_stm |> fragment_apply(frgmt)
    }
    |> prepared_statement.append_sql(" AND ")

  let prp_stm = case val_c {
    WhereColumn(col) -> prp_stm |> prepared_statement.append_sql(col)
    WhereParam(prm) -> {
      let nxt_plchldr_a = prp_stm |> prepared_statement.next_placeholder
      prp_stm |> prepared_statement.append_sql_and_param(nxt_plchldr_a, prm)
    }
    WhereFragment(frgmt) -> prp_stm |> fragment_apply(frgmt)
  }

  prp_stm
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Group By                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

pub type GroupBy {
  NoGroupBy
  // TODO: maybe use a Column type?
  GroupBy(columns: List(String))
}

pub fn group_by_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  group_by grpb: GroupBy,
) -> PreparedStatement {
  case grpb {
    NoGroupBy -> prp_stm
    GroupBy(grpbs) ->
      prp_stm
      |> prepared_statement.append_sql(" GROUP BY ")
      |> group_by_apply(grpbs)
  }
}

fn group_by_apply(
  prepared_statement prp_stm: PreparedStatement,
  group_bys grpbs: List(String),
) -> PreparedStatement {
  case grpbs {
    [] -> prp_stm
    _ ->
      grpbs
      |> list.fold(
        prp_stm,
        fn(new_prp_stm: PreparedStatement, s: String) -> PreparedStatement {
          case new_prp_stm == prp_stm {
            True -> new_prp_stm |> prepared_statement.append_sql(s)
            False -> new_prp_stm |> prepared_statement.append_sql(", " <> s)
          }
        },
      )
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Joins                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

pub type Joins {
  NoJoins
  Joins(List(Join))
}

pub type JoinKind {
  JoinTable(table: String)
  JoinSubQuery(sub_query: Query)
}

pub type Join {
  CrossJoin(with: JoinKind, alias: String)
  InnerJoin(with: JoinKind, alias: String, on: Where)
  LeftOuterJoin(with: JoinKind, alias: String, on: Where)
  RightOuterJoin(with: JoinKind, alias: String, on: Where)
  FullOuterJoin(with: JoinKind, alias: String, on: Where)
}

fn join_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  joins jns: Joins,
) -> PreparedStatement {
  case jns {
    Joins(parts) -> {
      parts
      |> list.fold(
        prp_stm,
        fn(new_prp_stm: PreparedStatement, prt: Join) -> PreparedStatement {
          let apply_join = fn(
            new_prp_stm: PreparedStatement,
            sql_command: String,
          ) -> PreparedStatement {
            new_prp_stm
            |> prepared_statement.append_sql(" " <> sql_command <> " ")
            |> join_apply(prt)
          }

          let apply_on = fn(new_prp_stm: PreparedStatement, on: Where) {
            new_prp_stm
            |> prepared_statement.append_sql(" ON ")
            |> where_apply(on)
          }

          case prt {
            CrossJoin(_, _) -> new_prp_stm |> apply_join("CROSS JOIN")
            InnerJoin(_, _, on: on) ->
              new_prp_stm |> apply_join("INNER JOIN") |> apply_on(on)
            LeftOuterJoin(_, _, on: on) ->
              new_prp_stm |> apply_join("LEFT OUTER JOIN") |> apply_on(on)
            RightOuterJoin(_, _, on: on) ->
              new_prp_stm |> apply_join("RIGHT OUTER JOIN") |> apply_on(on)
            FullOuterJoin(_, _, on: on) ->
              new_prp_stm |> apply_join("FULL OUTER JOIN") |> apply_on(on)
          }
        },
      )
    }
    NoJoins -> prp_stm
  }
}

fn join_apply(
  prepared_statement prp_stm: PreparedStatement,
  join prt: Join,
) -> PreparedStatement {
  case prt.with {
    JoinTable(table: tbl) ->
      prp_stm |> prepared_statement.append_sql(tbl <> " AS " <> prt.alias)
    JoinSubQuery(sub_query: qry) ->
      prp_stm
      |> prepared_statement.append_sql("(")
      |> builder_apply(qry)
      |> prepared_statement.append_sql(") AS " <> prt.alias)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Order By                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

pub type OrderBy {
  NoOrderBy
  OrderBy(values: List(OrderByValue))
}

pub type OrderByValue {
  OrderByColumn(column: String, direction: OrderByDirection)
  OrderByParam(param: Param, direction: OrderByDirection)
  OrderByFragment(fragment: Fragment, direction: OrderByDirection)
}

pub type OrderByDirection {
  Asc
  Desc
  AscNullsFirst
  DescNullsFirst
}

fn order_by_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  order_by ordb: OrderBy,
) -> PreparedStatement {
  case ordb {
    NoOrderBy -> prp_stm
    OrderBy(ordbs) -> {
      case ordbs {
        [] -> prp_stm
        vs -> {
          let prp_stm = prp_stm |> prepared_statement.append_sql(" ORDER BY ")
          vs
          |> list.fold(
            prp_stm,
            fn(new_prp_stm: PreparedStatement, v: OrderByValue) -> PreparedStatement {
              case new_prp_stm == prp_stm {
                True -> new_prp_stm |> order_by_value_apply(v)
                False ->
                  new_prp_stm
                  |> prepared_statement.append_sql(", ")
                  |> order_by_value_apply(v)
              }
            },
          )
        }
      }
    }
  }
}

fn order_by_value_apply(
  prepared_statement prp_stm: PreparedStatement,
  value v: OrderByValue,
) -> PreparedStatement {
  case v {
    OrderByColumn(col, dir) ->
      prp_stm
      |> prepared_statement.append_sql(col)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
    OrderByParam(param, dir) ->
      prp_stm
      |> prepared_statement.append_param(param)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
    OrderByFragment(frgmnt, dir) ->
      prp_stm
      |> fragment_apply(frgmnt)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
  }
}

fn order_by_direction_to_sql(
  order_by_direction ordbd: OrderByDirection,
) -> String {
  case ordbd {
    Asc -> "ASC NULLS LAST"
    Desc -> "DESC NULLS LAST"
    AscNullsFirst -> "ASC NULLS FIRST"
    DescNullsFirst -> "DESC NULLS FIRST"
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Limit & Offset                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

// TODO: Split limit and offset into separate types and separate functions
//       then add one combination function to set both limit and offset.
pub type LimitOffset {
  LimitOffset(limit: Int, offset: Int)
  LimitNoOffset(limit: Int)
  NoLimitOffset(offset: Int)
  NoLimitNoOffset
}

pub fn limit_offset_new(limit lmt: Int, offset offst: Int) -> LimitOffset {
  case lmt >= 0, offst >= 0 {
    True, True -> LimitOffset(limit: lmt, offset: offst)
    True, False -> LimitNoOffset(limit: lmt)
    False, _ -> NoLimitNoOffset
  }
}

pub fn limit_new(limit lmt: Int) -> LimitOffset {
  case lmt >= 0 {
    True -> LimitNoOffset(limit: lmt)
    False -> NoLimitNoOffset
  }
}

pub fn offset_new(offset offst: Int) -> LimitOffset {
  case offst >= 0 {
    True -> NoLimitOffset(offset: offst)
    False -> NoLimitNoOffset
  }
}

pub fn limit_offset_get(select_query qry: Select) -> LimitOffset {
  qry.limit_offset
}

fn limit_offset_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  limit_offset lmt_offst: LimitOffset,
) -> PreparedStatement {
  case lmt_offst {
    LimitOffset(limit: lmt, offset: offst) ->
      " LIMIT " <> int.to_string(lmt) <> " OFFSET " <> int.to_string(offst)
    LimitNoOffset(limit: lmt) -> " LIMIT " <> int.to_string(lmt)
    NoLimitOffset(offset: offst) -> " OFFSET " <> int.to_string(offst)
    NoLimitNoOffset -> ""
  }
  |> prepared_statement.append_sql(prp_stm, _)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Epilog                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Used to add a trailing SQL statement to the query.
///
pub type Epilog {
  NoEpilog
  Epilog(string: String)
}

fn epilog_apply(
  prepared_statement prp_stm: PreparedStatement,
  epilog prt: Epilog,
) -> PreparedStatement {
  case prt {
    NoEpilog -> prp_stm
    Epilog(string: eplg) -> prp_stm |> prepared_statement.append_sql(eplg)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Fragment                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

// TODO: Create injection checker, something like:
//
// `gleam run --module cake/sql-injection-check -- ./src`
//
// This could parse the gleam source and find spots
// where fragments are used and check if the inserted
// values are gleam constants only.
//
// This solution could potentially be extended to a Literal type
// that where a function takes a Literal the wrapped value (LiteralString, etc)
// must be a gleam constant - this could work across this whole query builder.

/// Fragments are used to insert raw SQL into the query.
///
/// NOTICE: Injecting input data into fragments is only safe when using
///         `FragmentPrepared` and only using literal strings in the
///         `fragment` field.
///
///          As a strategy it is recommended to ALWAYS USE MODULE CONSTANTS
///          for any `fragment`-field string.
///
pub type Fragment {
  FragmentLiteral(fragment: String)
  FragmentPrepared(fragment: String, params: List(Param))
}

/// Use to mark the position where a parameter should be inserted into
/// for a fragment with a prepared parameter.
///
pub const fragment_placeholder_grapheme = "$"

/// Splits something like `GREATER($, $)` into `["GREATER(", "$", ", ", "$", ")"]`.
///
pub fn fragment_prepared_split_string(
  string_fragment str_frgmt: String,
) -> List(String) {
  str_frgmt
  |> string.to_graphemes
  |> list.fold([], fn(acc: List(String), grapheme: String) -> List(String) {
    case grapheme == fragment_placeholder_grapheme, acc {
      // If encountering a placeholder, we want to add it as a single item.
      True, _acc -> [fragment_placeholder_grapheme, ..acc]
      // If Encountering anything else but there isn't anything yet,
      // we want to add it as a single item.
      False, [] -> [grapheme]
      // If the previous item matches a placeholder, we don't want to append
      // to it, because we want placeholders to exist as separat single items.
      False, [first, ..] if first == fragment_placeholder_grapheme -> {
        [grapheme, ..acc]
      }
      // In any other case we can just append to the previous item
      False, [first, ..rest] -> {
        [first <> grapheme, ..rest]
      }
    }
  })
  |> list.reverse
}

pub fn fragment_count_placeholders(
  string_fragments s_frgmts: List(String),
) -> Int {
  s_frgmts
  |> list.fold(0, fn(count: Int, s_frgmt: String) -> Int {
    case s_frgmt == fragment_placeholder_grapheme {
      True -> count + 1
      False -> count
    }
  })
}

fn fragment_apply(
  prepared_statement prp_stm: PreparedStatement,
  fragment frgmt: Fragment,
) -> PreparedStatement {
  case frgmt {
    FragmentLiteral(fragment: frgmt) ->
      prp_stm |> prepared_statement.append_sql(frgmt)
    FragmentPrepared(fragment: frgmt, params: []) ->
      prp_stm |> prepared_statement.append_sql(frgmt)
    FragmentPrepared(fragment: frgmt, params: prms) -> {
      let frgmts = frgmt |> fragment_prepared_split_string
      let frgmt_plchldr_count = frgmts |> fragment_count_placeholders
      let prms_count = prms |> list.length
      // Fill up or reduce params to match the given number of placeholders
      //
      // This is likely a user error that cannot be catched by
      // the type system, but instead of crashing we do the best we can:
      //
      // For the user ´fragment.prepared()` should be used with caution and
      // will warn about the mismatch at runtime.
      let prms = case frgmt_plchldr_count |> int.compare(with: prms_count) {
        order.Eq -> prms
        order.Lt -> {
          // If there are more params than placeholders, we take the first
          // `n` params where `n` is the number of placeholders, and discard
          // the rest.
          let missing_placeholders = prms_count - frgmt_plchldr_count
          prms |> list.take(missing_placeholders + 1)
        }
        order.Gt -> {
          // If there are more placeholders than params, we repeat the last
          // param until the number of placeholders is reached.
          let missing_params = frgmt_plchldr_count - prms_count
          // At this point one can assume a non-empty-list for the params
          // because `fragment.prepared()` converts a call with `0`
          // placeholders andor `0` params to `FragmentLiteral` which needs
          // neither placeholders nor params.
          let assert Ok(last_item) = list.last(prms)
          let repeated_last_item = last_item |> list.repeat(missing_params)
          prms |> list.append(repeated_last_item)
        }
      }

      let #(new_prp_stm, param_rest) =
        frgmts
        |> list.fold(
          #(prp_stm, prms),
          fn(acc: #(PreparedStatement, List(Param)), frgmnt: String) -> #(
            PreparedStatement,
            List(Param),
          ) {
            let new_prp_stm = acc.0

            case frgmnt == fragment_placeholder_grapheme {
              True -> {
                let nxt_plchldr =
                  new_prp_stm |> prepared_statement.next_placeholder

                // Pop one of the list, and use it as the next parameter value.
                // This is safe because we have already checked that the list
                // is not empty.
                let assert [prm, ..rest_prms] = acc.1

                let new_prp_stm =
                  new_prp_stm
                  |> prepared_statement.append_sql_and_param(nxt_plchldr, prm)

                #(new_prp_stm, rest_prms)
              }
              False -> {
                #(new_prp_stm |> prepared_statement.append_sql(frgmnt), acc.1)
              }
            }
          },
        )

      let _sanity_check_all_params_have_been_used = case param_rest {
        [] -> True
        _ -> {
          let crash_msg =
            "The number of placeholders in the fragment does not match the number of parameters. This is likely a user error. Please check the fragment and the parameters."
          panic as crash_msg
        }
      }

      new_prp_stm
    }
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Helpers                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn qualified_identifier(scope scp: String) -> fn(String) -> String {
  fn(identifier) -> String { scp <> "." <> identifier }
}
