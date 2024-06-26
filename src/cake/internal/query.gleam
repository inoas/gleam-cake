//// Contains types and composition functions to build _read queries_.
////
//// _Read queries_ are in essence SELECT and combined queries such as `UNION`,
//// `UNION ALL`, `INTERSECT`, 'EXCECEPT', etc. which combine multiple `SELECT`
//// queries into one query.
////
//// ## Notice
////
//// The included types are all non-opaque public, so that you _CAN_ build
//// whatever you want in userland code, however the whole module is internal
//// because you _SHOULD NOT_ build queries based on raw types manually.
////
//// Because the likihood of creating invalid queries is mich higher than using
//// the interface modules found in `cake/query/*`.
////
//// WARNING: Once the library has matured, public access to these types _may_
//// vanish.
////
//// ## Scope
////
//// The functions of this module are mostly concerned about either of these two
//// things:
////
//// 1. Building complex nested custom types that represent read queries.
//// 2. Converting these complex nested custom types into SQL including all the
////    necessary prepared statement placeholders and parameters.
////
//// The complex nested types are setup in a way that most values are wrapped
//// (or boxed) even if that would not be required technically, simply to
//// enhance the debugging experience and thus make it easier to reason about
//// the query structure when composing different queries.
////

// TODO: Add to query validator in v2 or v3

import cake/dialect.{type Dialect, Maria, Postgres, Sqlite}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/param.{type Param}
import gleam/int
import gleam/list
import gleam/order
import gleam/string

/// Used by cake internally to prefix computed aliases.
///
pub const computed_alias_prefix = "__cake_computed_alias_"

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Query                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// A query can be either a `SELECT` query or a combined query.
///
/// A combined query is a query that combines multiple `SELECT` queries into one
/// query using `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`, etc.
///
pub type Query {
  SelectQuery(query: Select)
  CombinedQuery(query: Combined)
}

/// Creates a prepared statement from a query.
///
pub fn to_prepared_statement(
  query qry: Query,
  plchldr_bs prp_stm_prfx: String,
  dialect dlct: Dialect,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new(dialect: dlct)
  |> apply(qry)
}

/// Applies a query to a prepared statement.
///
pub fn apply(
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
  |> limit_clause_apply(qry.limit)
  |> offset_clause_apply(qry.offset)
  |> epilog_apply(qry.epilog)
  |> comment_apply(qry.comment)
}

/// Applies a combined query to a prepared statement.
///
pub fn combined_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  combined_query qry: Combined,
) -> PreparedStatement {
  let sql_command = case qry.kind {
    UnionDistinct -> "UNION"
    UnionAll -> "UNION ALL"
    ExceptDistinct -> "EXCEPT"
    ExceptAll -> "EXCEPT ALL"
    IntersectDistinct -> "INTERSECT"
    IntersectAll -> "INTERSECT ALL"
  }

  // `LIMIT`, `OFFSET` and `ORDER BY` is non-standard SQL within queries nested
  // in UNION and its siblings (combined queries) but they do work on MariaDB
  // and PostgreSQL out of the box,
  // see <https://github.com/diesel-rs/diesel/issues/3151>.
  //
  // For SQLite we are wrapping them in sub-queries, like so:
  //
  // ```sql
  // SELECT * FROM (SELECT * FROM cats LIMIT 3) AS c1
  // UNION ALL
  // SELECT * FROM (SELECT * FROM cats OFFSET 2) AS c2
  // LIMIT 1
  // ```

  let open_nested_query = fn(prp_stm: PreparedStatement) -> PreparedStatement {
    case prp_stm |> prepared_statement.get_dialect() {
      Sqlite -> prp_stm |> prepared_statement.append_sql("SELECT * FROM (")
      _ -> prp_stm |> prepared_statement.append_sql("(")
    }
  }

  let close_nested_query = fn(prp_stm: PreparedStatement, nested_index: Int) -> PreparedStatement {
    case prp_stm |> prepared_statement.get_dialect() {
      Sqlite ->
        prp_stm
        |> prepared_statement.append_sql(
          ") AS " <> computed_alias_prefix <> nested_index |> int.to_string,
        )
      _ -> prp_stm |> prepared_statement.append_sql(")")
    }
  }

  let prp_stm = prp_stm |> open_nested_query
  let #(new_prp_stm, nested_index) =
    qry.queries
    |> list.fold(
      #(prp_stm, 0),
      fn(acc: #(PreparedStatement, Int), qry: Select) -> #(
        PreparedStatement,
        Int,
      ) {
        let #(new_prp_stm, nested_index) = acc
        case new_prp_stm == prp_stm {
          True -> #(new_prp_stm |> select_builder(qry), nested_index)
          False -> {
            let nested_index = nested_index + 1
            let new_prp_stm =
              new_prp_stm
              |> close_nested_query(nested_index)
              |> prepared_statement.append_sql(" " <> sql_command <> " ")
              |> open_nested_query
              |> select_builder(qry)

            #(new_prp_stm, nested_index)
          }
        }
      },
    )
  new_prp_stm |> close_nested_query(nested_index + 1)
}

/// A combined query.
///
pub type Combined {
  Combined(
    kind: CombinedQueryKind,
    queries: List(Select),
    limit: Limit,
    offset: Offset,
    order_by: OrderBy,
    epilog: Epilog,
    comment: Comment,
  )
}

/// NOTICE: SQLite does not support `EXCEPT ALL` (`ExceptAll`) nor
/// `INTERSECT ALL` (`IntersectAll`).
///
pub type CombinedQueryKind {
  UnionDistinct
  UnionAll
  ExceptDistinct
  ExceptAll
  IntersectDistinct
  IntersectAll
}

// TODO v2 Also allow nested combined (aka UNION of UNIONs, etc)
// from any nested SELECT

/// Creates a new combined query.
///
pub fn combined_query_new(
  kind knd: CombinedQueryKind,
  queries qrys: List(Select),
) -> Combined {
  qrys
  |> Combined(
    kind: knd,
    queries: _,
    limit: NoLimit,
    offset: NoOffset,
    order_by: NoOrderBy,
    epilog: NoEpilog,
    comment: NoComment,
  )
}

/// Sets or appends an `ORDER BY` clause to a combined query.
///
pub fn combined_order_by(
  query qry: Combined,
  by ordb: OrderBy,
  append appnd: Bool,
) -> Combined {
  case appnd {
    True -> Combined(..qry, order_by: qry.order_by |> order_by_append(ordb))
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
  |> select_clause_apply(qry.kind, qry.select)
  |> from_clause_apply(qry.from)
  |> join_clause_apply(qry.join)
  |> where_clause_apply(qry.where)
  |> group_by_clause_apply(qry.group_by)
  |> having_clause_apply(qry.having)
  |> order_by_clause_apply(qry.order_by)
  |> limit_clause_apply(qry.limit)
  |> offset_clause_apply(qry.offset)
  |> epilog_apply(qry.epilog)
  |> comment_apply(qry.comment)
}

/// Decribes if a `SELECT` query should return all rows or only distinct rows.
///
pub type SelectKind {
  SelectAll
  SelectDistinct
}

/// A `SELECT` query.
///
pub type Select {
  Select(
    // with (_recursive?): ?, // v2
    kind: SelectKind,
    select: Selects,
    // window: ?, // v2
    from: From,
    join: Joins,
    where: Where,
    group_by: GroupBy,
    having: Where,
    order_by: OrderBy,
    limit: Limit,
    offset: Offset,
    epilog: Epilog,
    comment: Comment,
  )
}

/// Sets or append an `ORDER BY` clause to a `SELECT` query.
///
pub fn select_order_by(
  select_query qry: Select,
  by ordb: OrderBy,
  append appnd: Bool,
) -> Select {
  case appnd {
    True -> Select(..qry, order_by: qry.order_by |> order_by_append(ordb))
    False -> Select(..qry, order_by: ordb)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Selects                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declares the projection of a `SELECT` query.
///
/// If no columns are selected, all columns are returned, aka `SELECT *`.
///
pub type Selects {
  NoSelects
  Selects(List(SelectValue))
}

/// A value that can be selected in a `SELECT` query.
/// It can be a column, a parameter, a fragment, or a value with an alias.
///
/// TODO v2 Investigate -> probably makes no sense to have params/values in SELECT?
///
pub type SelectValue {
  SelectColumn(column: String)
  // TODO v2 Investigate -> probably makes no sense to have params in SELECT?
  SelectParam(param: Param)
  SelectFragment(fragment: Fragment)
  SelectAlias(value: SelectValue, alias: String)
}

fn select_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  kind knd: SelectKind,
  selects slcts: Selects,
) -> PreparedStatement {
  let select_command = case knd {
    SelectAll -> "SELECT"
    SelectDistinct -> "SELECT DISTINCT"
  }
  case slcts {
    NoSelects ->
      prp_stm |> prepared_statement.append_sql(select_command <> " *")
    Selects(slct_vs) -> {
      case slct_vs {
        [] -> prp_stm
        vs -> {
          let prp_stm =
            prp_stm |> prepared_statement.append_sql(select_command <> " ")
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
    SelectParam(prm) -> prp_stm |> prepared_statement.append_param(prm)
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

/// Describes the `FROM` clause of SQL queries.
///
pub type From {
  NoFrom
  // TODO v2 Check if the table or view does indeed exist
  // => should be a function somewhere but not here
  // TODO v2 Could be a list of tables/views
  // TODO v2 FromTable(names: List(String))
  // TODO v2 FromSubQuery(sub_queries: List(#(sub_query: Query, alias: String)))
  // interfacing functions should exist to specify a single item or a list
  FromTable(name: String)
  FromSubQuery(sub_query: Query, alias: String)
}

/// Applies the `FROM` clause to a prepared statement by appending the SQL code.
///
pub fn from_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  from frm: From,
) -> PreparedStatement {
  case frm {
    NoFrom -> prp_stm
    FromTable(tbl) -> prp_stm |> prepared_statement.append_sql(" FROM " <> tbl)
    FromSubQuery(qry, als) ->
      prp_stm
      |> prepared_statement.append_sql(" FROM (")
      |> apply(qry)
      |> prepared_statement.append_sql(") AS " <> als)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Where                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Describes the `WHERE` clause of SQL queries.
///
/// NOTICE: SQLite does _not_ support:
///
/// - `ANY` (`WhereAny*`),
/// - `ALL` (`WhereAny*`) and,
/// - `SIMILAR TO (WhereSimilarTo)`
///
pub type Where {
  NoWhere
  NotWhere(where: Where)
  AndWhere(wheres: List(Where))
  OrWhere(wheres: List(Where))
  XorWhere(wheres: List(Where))
  WhereIsBool(value: WhereValue, bool: Bool)
  WhereIsNotBool(value: WhereValue, bool: Bool)
  WhereIsNull(value: WhereValue)
  WhereIsNotNull(value: WhereValue)
  WhereComparison(
    value_a: WhereValue,
    operator: WhereComparisonOperator,
    value_b: WhereValue,
  )
  WhereAnyOfSubQuery(
    value_a: WhereValue,
    operator: WhereComparisonOperator,
    sub_query: Query,
  )
  WhereAllOfSubQuery(
    value_a: WhereValue,
    operator: WhereComparisonOperator,
    sub_query: Query,
  )
  WhereIn(value: WhereValue, values: List(WhereValue))
  WhereExistsInSubQuery(sub_query: Query)
  WhereBetween(value_a: WhereValue, value_b: WhereValue, value_c: WhereValue)
  WhereLike(value: WhereValue, string: String)
  WhereILike(value: WhereValue, string: String)
  WhereSimilarTo(value: WhereValue, string: String)
  WhereFragment(fragment: Fragment)
}

/// Describes the comparison operators for the `WHERE` clause of SQL queries.
///
pub type WhereComparisonOperator {
  Equal
  Greater
  GreaterOrEqual
  Lower
  LowerOrEqual
  Unequal
}

/// Describes the values for the `WHERE` clause of SQL queries.
///
pub type WhereValue {
  WhereColumnValue(column: String)
  WhereParamValue(param: Param)
  WhereFragmentValue(fragment: Fragment)
  // NOTICE: For some commands, the return value must be scalar:
  // e.g. a result of 1 column, 1 row (LIMIT 1, and a single
  // projection aka SELECT value)
  //
  // TODO v3 If there are multiple, take the list of select values (projections)
  // and return the last one, if there is none, return NULL
  // And also potentially apply LIMIT 1?
  WhereSubQueryValue(sub_query: Query)
}

/// Applies the `WHERE` clause to a prepared statement by appending the SQL code.
///
pub fn where_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prp_stm
    _ -> prp_stm |> prepared_statement.append_sql(" WHERE ") |> where_apply(wh)
  }
}

fn having_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prp_stm
    _ -> prp_stm |> prepared_statement.append_sql(" HAVING ") |> where_apply(wh)
  }
}

fn where_apply(
  prepared_statement prp_stm: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prp_stm
    AndWhere(whs) -> prp_stm |> where_logical_operator_apply("AND", whs, False)
    OrWhere(whs) -> prp_stm |> where_logical_operator_apply("OR", whs, True)
    XorWhere(whs) -> prp_stm |> where_xor_apply(whs)
    NotWhere(wh) ->
      prp_stm
      |> prepared_statement.append_sql("NOT(")
      |> where_apply(wh)
      |> prepared_statement.append_sql(")")
    WhereIsBool(val, True) -> prp_stm |> where_literal_apply(val, "IS TRUE")
    WhereIsBool(val, False) -> prp_stm |> where_literal_apply(val, "IS FALSE")
    WhereIsNotBool(val, True) ->
      prp_stm |> where_literal_apply(val, "IS NOT TRUE")
    WhereIsNotBool(val, False) ->
      prp_stm |> where_literal_apply(val, "IS NOT FALSE")
    WhereIsNull(val) -> prp_stm |> where_literal_apply(val, "IS NULL")
    WhereIsNotNull(val) -> prp_stm |> where_literal_apply(val, "IS NOT NULL")
    WhereComparison(val_a, Equal, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "=", val_b)
    WhereComparison(val_a, Greater, val_b) ->
      prp_stm |> where_comparison_apply(val_a, ">", val_b)
    WhereComparison(val_a, GreaterOrEqual, val_b) ->
      prp_stm |> where_comparison_apply(val_a, ">=", val_b)
    WhereComparison(val_a, Lower, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<", val_b)
    WhereComparison(val_a, LowerOrEqual, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<=", val_b)
    WhereComparison(val_a, Unequal, val_b) ->
      prp_stm |> where_comparison_apply(val_a, "<>", val_b)
    WhereAnyOfSubQuery(val, Equal, qry) ->
      prp_stm |> where_literal_apply(val, "= ANY") |> where_sub_query_apply(qry)
    WhereAnyOfSubQuery(val, Greater, qry) ->
      prp_stm |> where_literal_apply(val, "> ANY") |> where_sub_query_apply(qry)
    WhereAnyOfSubQuery(val, GreaterOrEqual, qry) ->
      prp_stm
      |> where_literal_apply(val, ">= ANY")
      |> where_sub_query_apply(qry)
    WhereAnyOfSubQuery(val, Lower, qry) ->
      prp_stm |> where_literal_apply(val, "< ANY") |> where_sub_query_apply(qry)
    WhereAnyOfSubQuery(val, LowerOrEqual, qry) ->
      prp_stm
      |> where_literal_apply(val, "<= ANY")
      |> where_sub_query_apply(qry)
    WhereAnyOfSubQuery(val, Unequal, qry) ->
      prp_stm
      |> where_literal_apply(val, "<> ANY")
      |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, Equal, qry) ->
      prp_stm |> where_literal_apply(val, "= ALL") |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, Greater, qry) ->
      prp_stm |> where_literal_apply(val, "> ALL") |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, GreaterOrEqual, qry) ->
      prp_stm
      |> where_literal_apply(val, ">= ALL")
      |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, Lower, qry) ->
      prp_stm |> where_literal_apply(val, "< ALL") |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, LowerOrEqual, qry) ->
      prp_stm
      |> where_literal_apply(val, "<= ALL")
      |> where_sub_query_apply(qry)
    WhereAllOfSubQuery(val, Unequal, qry) ->
      prp_stm
      |> where_literal_apply(val, "<> ALL")
      |> where_sub_query_apply(qry)
    WhereBetween(val_a, val_b, val_c) ->
      prp_stm |> where_between_apply(val_a, val_b, val_c)
    WhereIn(val, vals) -> prp_stm |> where_value_in_values_apply(val, vals)
    WhereExistsInSubQuery(qry) ->
      prp_stm
      |> prepared_statement.append_sql(" EXISTS ")
      |> where_sub_query_apply(qry)
    WhereLike(val, prm) ->
      prp_stm
      |> where_comparison_apply(
        val,
        "LIKE",
        prm |> param.StringParam |> WhereParamValue,
      )
    WhereILike(val, prm) ->
      prp_stm
      |> where_comparison_apply(
        val,
        "ILIKE",
        prm |> param.StringParam |> WhereParamValue,
      )
    WhereSimilarTo(val, prm) ->
      prp_stm
      |> where_comparison_apply(
        val,
        "SIMILAR TO",
        prm |> param.StringParam |> WhereParamValue,
      )
      |> prepared_statement.append_sql(" ESCAPE '/'")
    WhereFragment(fragment) -> prp_stm |> fragment_apply(fragment)
  }
}

fn where_literal_apply(
  prepared_statement prp_stm: PreparedStatement,
  value v: WhereValue,
  literal lt: String,
) -> PreparedStatement {
  case v {
    WhereColumnValue(col) ->
      prp_stm |> prepared_statement.append_sql(col <> " " <> lt)
    WhereParamValue(prm) -> prp_stm |> prepared_statement.append_param(prm)
    WhereFragmentValue(fragment: frgmt) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> prepared_statement.append_sql(" " <> lt)
    WhereSubQueryValue(qry) ->
      prp_stm
      |> where_sub_query_apply(qry)
      |> prepared_statement.append_sql(" " <> lt)
  }
}

fn where_comparison_apply(
  prepared_statement prp_stm: PreparedStatement,
  value_a val_a: WhereValue,
  operator oprtr: String,
  value_b val_b: WhereValue,
) -> PreparedStatement {
  case val_a, val_b {
    WhereColumnValue(col_a), WhereColumnValue(col_b) ->
      prp_stm
      |> where_string_apply(col_a <> " " <> oprtr <> " " <> col_b)
    WhereColumnValue(col), WhereParamValue(prm) ->
      prp_stm
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> where_param_apply(prm)
    WhereParamValue(prm), WhereColumnValue(col) ->
      prp_stm
      |> where_param_apply(prm)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereParamValue(prm_a), WhereParamValue(prm_b) ->
      prp_stm
      |> where_param_apply(prm_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(prm_b)
    WhereFragmentValue(frgmt), WhereColumnValue(col) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereColumnValue(col), WhereFragmentValue(frgmt) ->
      prp_stm
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> fragment_apply(frgmt)
    WhereFragmentValue(frgmt), WhereParamValue(prm) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(prm)
    WhereParamValue(prm), WhereFragmentValue(frgmt) ->
      prp_stm
      |> where_param_apply(prm)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(frgmt)
    WhereFragmentValue(frgmt_a), WhereFragmentValue(frgmt_b) ->
      prp_stm
      |> fragment_apply(frgmt_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(frgmt_b)
    WhereSubQueryValue(qry_a), WhereSubQueryValue(qry_b) ->
      prp_stm
      |> where_sub_query_apply(qry_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(qry_b)
    WhereColumnValue(col), WhereSubQueryValue(qry) ->
      prp_stm
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> where_sub_query_apply(qry)
    WhereSubQueryValue(qry), WhereColumnValue(col) ->
      prp_stm
      |> where_sub_query_apply(qry)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereParamValue(prm), WhereSubQueryValue(qry) ->
      prp_stm
      |> where_param_apply(prm)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(qry)
    WhereSubQueryValue(qry), WhereParamValue(prm) ->
      prp_stm
      |> where_sub_query_apply(qry)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(prm)
    WhereFragmentValue(frgmt), WhereSubQueryValue(qry) ->
      prp_stm
      |> fragment_apply(frgmt)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(qry)
    WhereSubQueryValue(qry), WhereFragmentValue(frgmt) ->
      prp_stm
      |> where_sub_query_apply(qry)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(frgmt)
  }
}

fn where_string_apply(
  prepared_statement prp_stm: PreparedStatement,
  string s: String,
) -> PreparedStatement {
  prp_stm |> prepared_statement.append_sql(s)
}

fn where_param_apply(
  prepared_statement prp_stm: PreparedStatement,
  param prm: Param,
) -> PreparedStatement {
  prp_stm |> prepared_statement.append_param(prm)
}

fn where_sub_query_apply(
  prepared_statement prp_stm: PreparedStatement,
  sub_query qry: Query,
) -> PreparedStatement {
  prp_stm
  |> prepared_statement.append_sql("(")
  |> apply(qry)
  |> prepared_statement.append_sql(")")
}

fn where_logical_operator_apply(
  prepared_statement prp_stm: PreparedStatement,
  operator oprtr: String,
  where whs: List(Where),
  wrap_in_parentheses wrp_prns: Bool,
) -> PreparedStatement {
  let prp_stm = case wrp_prns {
    True -> prp_stm |> prepared_statement.append_sql("(")
    False -> prp_stm
  }

  let prp_stm =
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

  let prp_stm = case wrp_prns {
    True -> prp_stm |> prepared_statement.append_sql(")")
    False -> prp_stm
  }

  prp_stm
}

fn where_xor_apply(
  prepared_statement prp_stm: PreparedStatement,
  where whs: List(Where),
) -> PreparedStatement {
  case prp_stm |> prepared_statement.get_dialect() {
    Postgres | Sqlite -> custom_where_xor_apply(prp_stm, whs)
    Maria -> vanilla_where_xor_apply(prp_stm, whs)
  }
}

fn custom_where_xor_apply(
  prepared_statement prp_stm: PreparedStatement,
  where whs: List(Where),
) -> PreparedStatement {
  let xor_idxs = whs |> list.length |> int.subtract(1) |> list.range(0, _)

  let prp_stm = prp_stm |> prepared_statement.append_sql("(")

  let prp_stm =
    xor_idxs
    |> list.fold(
      prp_stm,
      fn(new_prp_stm: PreparedStatement, xor_idx: Int) -> PreparedStatement {
        let new_prp_stm = case new_prp_stm == prp_stm {
          True -> new_prp_stm
          False -> new_prp_stm |> prepared_statement.append_sql(") OR (")
        }

        let #(new_prp_stm, _last_wh_idx) =
          whs
          |> list.fold(
            #(new_prp_stm, 0),
            fn(acc: #(PreparedStatement, Int), wh: Where) -> #(
              PreparedStatement,
              Int,
            ) {
              let #(new_prp_stm_per_xor, wh_idx) = acc
              let new_prp_stm_per_xor = case wh_idx == xor_idx, wh_idx {
                True, 0 -> new_prp_stm_per_xor |> where_apply(wh)

                True, _gt_0 ->
                  new_prp_stm_per_xor
                  |> prepared_statement.append_sql(" AND (")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
                False, 0 ->
                  new_prp_stm_per_xor
                  |> prepared_statement.append_sql("NOT(")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
                False, _gt_0 ->
                  new_prp_stm_per_xor
                  |> prepared_statement.append_sql(" AND NOT(")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
              }
              #(new_prp_stm_per_xor, wh_idx + 1)
            },
          )

        new_prp_stm
      },
    )

  let prp_stm = prp_stm |> prepared_statement.append_sql(")")

  prp_stm
}

// MySQL/MariaDB could take this instead:
fn vanilla_where_xor_apply(
  prepared_statement prp_stm: PreparedStatement,
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
          |> prepared_statement.append_sql(" XOR ")
          |> where_apply(wh)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_value_in_values_apply(
  prepared_statement prp_stm: PreparedStatement,
  value val: WhereValue,
  parameters prms: List(WhereValue),
) -> PreparedStatement {
  let prp_stm =
    case val {
      WhereColumnValue(col) -> prp_stm |> prepared_statement.append_sql(col)
      WhereParamValue(prm) -> prp_stm |> prepared_statement.append_param(prm)
      WhereFragmentValue(frgmt) -> prp_stm |> fragment_apply(frgmt)
      WhereSubQueryValue(qry) -> prp_stm |> where_sub_query_apply(qry)
    }
    |> prepared_statement.append_sql(" IN (")

  prms
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, v: WhereValue) -> PreparedStatement {
      case v {
        WhereColumnValue(col) ->
          case new_prp_stm == prp_stm {
            True -> new_prp_stm |> prepared_statement.append_sql(col)
            False -> new_prp_stm |> prepared_statement.append_sql(", " <> col)
          }
        WhereParamValue(prm) ->
          case new_prp_stm == prp_stm {
            True -> ""
            False -> ", "
          }
          |> prepared_statement.append_sql(new_prp_stm, _)
          |> prepared_statement.append_param(prm)
        WhereFragmentValue(frgmt) -> prp_stm |> fragment_apply(frgmt)
        WhereSubQueryValue(qry) -> prp_stm |> where_sub_query_apply(qry)
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
  let prp_stm = case val_a {
    WhereColumnValue(col) -> prp_stm |> prepared_statement.append_sql(col)
    WhereParamValue(prm) -> prp_stm |> prepared_statement.append_param(prm)
    WhereFragmentValue(frgmt) -> prp_stm |> fragment_apply(frgmt)
    WhereSubQueryValue(qry) -> prp_stm |> where_sub_query_apply(qry)
  }

  let prp_stm = prp_stm |> prepared_statement.append_sql(" BETWEEN ")

  let prp_stm = case val_b {
    WhereColumnValue(col) -> prp_stm |> prepared_statement.append_sql(col)
    WhereParamValue(prm) -> prp_stm |> prepared_statement.append_param(prm)
    WhereFragmentValue(frgmt) -> prp_stm |> fragment_apply(frgmt)
    WhereSubQueryValue(qry) -> prp_stm |> where_sub_query_apply(qry)
  }

  let prp_stm = prp_stm |> prepared_statement.append_sql(" AND ")

  let prp_stm = case val_c {
    WhereColumnValue(col) -> prp_stm |> prepared_statement.append_sql(col)
    WhereParamValue(prm) -> prp_stm |> prepared_statement.append_param(prm)
    WhereFragmentValue(frgmt) -> prp_stm |> fragment_apply(frgmt)
    WhereSubQueryValue(qry) -> prp_stm |> where_sub_query_apply(qry)
  }

  prp_stm
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Group By                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

/// Group by clause
///
pub type GroupBy {
  NoGroupBy
  GroupBy(columns: List(String))
}

/// Apply group by clause to prepared statement
///
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

/// Tables, views and sub-queries can be joined together.
///
/// ## Supported join kinds
///
/// - `INNER JOIN`
/// - `LEFT JOIN`, inclusive, same as `LEFT OUTER JOIN`,
/// - `RIGHT JOIN`, inclusive, same as `RIGHT OUTER JOIN`,
/// - `FULL JOIN`, inclusive, same as `FULL OUTER JOIN`,
/// - `CROSS JOIN`
///
/// You can also build following joins using the provided query builder
/// functions:
///
/// - `SELF JOIN`: Use the same table, view, or sub-query with a different
///    alias.
/// - `EXCLUSIVE LEFT JOIN`: `WHERE b.key IS NULL`
/// - `EXCLUSIVE RIGHT JOIN`: `WHERE a.key IS NULL`
/// - `EXCLUSIVE FULL JOIN`: `WHERE a.key IS NULL OR b.key IS NULL`
///
pub type Joins {
  NoJoins
  Joins(List(Join))
}

/// The join target can be bei either a table or a sub-query.
///
pub type JoinTarget {
  JoinTable(table: String)
  JoinSubQuery(sub_query: Query)
}

/// A Join can be one of:
///
/// - `InnerJoin`: `INNER JOIN`
/// - `LeftJoin`: `LEFT JOIN`
/// - `RightJoin`: `RIGHT JOIN`
/// - `FullJoin`: `FULL JOIN`
/// - `CrossJoin`: `CROSS JOIN`
///
pub type Join {
  InnerJoin(with: JoinTarget, alias: String, on: Where)
  LeftJoin(with: JoinTarget, alias: String, on: Where)
  RightJoin(with: JoinTarget, alias: String, on: Where)
  FullJoin(with: JoinTarget, alias: String, on: Where)
  CrossJoin(with: JoinTarget, alias: String)
}

/// Apply join clauses to prepared statement.
///
pub fn join_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  joins jns: Joins,
) -> PreparedStatement {
  case jns {
    Joins(jns) -> {
      jns
      |> list.fold(
        prp_stm,
        fn(new_prp_stm: PreparedStatement, jn: Join) -> PreparedStatement {
          let join_command_apply = fn(
            new_prp_stm: PreparedStatement,
            sql_command: String,
          ) -> PreparedStatement {
            new_prp_stm
            |> prepared_statement.append_sql(" " <> sql_command <> " ")
            |> join_apply(jn)
          }

          let on_apply = fn(new_prp_stm: PreparedStatement, on: Where) -> PreparedStatement {
            new_prp_stm
            |> prepared_statement.append_sql(" ON ")
            |> where_apply(on)
          }

          case jn {
            InnerJoin(_, _, on: on) ->
              new_prp_stm |> join_command_apply("INNER JOIN") |> on_apply(on)
            LeftJoin(_, _, on: on) ->
              new_prp_stm
              |> join_command_apply("LEFT OUTER JOIN")
              |> on_apply(on)
            RightJoin(_, _, on: on) ->
              new_prp_stm
              |> join_command_apply("RIGHT OUTER JOIN")
              |> on_apply(on)
            FullJoin(_, _, on: on) ->
              new_prp_stm
              |> join_command_apply("FULL OUTER JOIN")
              |> on_apply(on)
            CrossJoin(_, _) -> new_prp_stm |> join_command_apply("CROSS JOIN")
          }
        },
      )
    }
    NoJoins -> prp_stm
  }
}

pub fn join_apply(
  prepared_statement prp_stm: PreparedStatement,
  join jn: Join,
) -> PreparedStatement {
  case jn.with {
    JoinTable(table: tbl) ->
      prp_stm |> prepared_statement.append_sql(tbl <> " AS " <> jn.alias)
    JoinSubQuery(sub_query: qry) ->
      prp_stm
      |> prepared_statement.append_sql("(")
      |> apply(qry)
      |> prepared_statement.append_sql(") AS " <> jn.alias)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Order By                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare an order by clause.
///
pub type OrderBy {
  NoOrderBy
  OrderBy(values: List(OrderByValue))
}

/// Order by values can be either a column or a fragment.
///
pub type OrderByValue {
  OrderByColumn(column: String, direction: OrderByDirection)
  OrderByFragment(fragment: Fragment, direction: OrderByDirection)
}

/// Order by direction can be one of:
///
/// - `Asc` - Ascending order
/// - `AscNullsFirst` - Ascending order with nulls first, not supported by
///   MariaDB/MySQL
/// - `AscNullsLast` - Ascending order with nulls last, not supported by
///   MariaDB/MySQL
/// - `Desc` - Descending order
/// - `DescNullsFirst` - Descending order with nulls first, not supported by
///    MariaDB/MySQL
/// - `DescNullsLast` - Descending order with nulls last, not supported by
///    MariaDB/MySQL
///
pub type OrderByDirection {
  Asc
  AscNullsFirst
  AscNullsLast
  Desc
  DescNullsFirst
  DescNullsLast
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
    OrderByFragment(frgmnt, dir) ->
      prp_stm
      |> fragment_apply(frgmnt)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
  }
}

/// NOTICE: MariaDB/MySQL do not support `NULLS FIRST` or `NULLS LAST`. Instead,
/// `NULL`s are considered to have the lowest value, thus ordering in `DESC`
/// order will see the `NULL`s appearing last. To force `NULL`s to be regarded
/// as highest values, see <https://mariadb.com/kb/en/null-values/#ordering>.
///
fn order_by_direction_to_sql(
  order_by_direction ordbd: OrderByDirection,
) -> String {
  case ordbd {
    Asc -> "ASC"
    AscNullsFirst -> "ASC NULLS FIRST"
    AscNullsLast -> "ASC NULLS LAST"
    Desc -> "DESC"
    DescNullsFirst -> "DESC NULLS FIRST"
    DescNullsLast -> "DESC NULLS LAST"
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Limit                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare a limit clause.
///
pub type Limit {
  NoLimit
  Limit(limit: Int)
}

/// Create a new limit clause.
///
pub fn limit_new(limit lmt: Int) -> Limit {
  case lmt > 0 {
    False -> NoLimit
    True -> Limit(limit: lmt)
  }
}

fn limit_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  limit lmt: Limit,
) -> PreparedStatement {
  case lmt {
    NoLimit -> ""
    Limit(limit: lmt) -> " LIMIT " <> lmt |> int.to_string
  }
  |> prepared_statement.append_sql(prp_stm, _)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Offset                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare an offset clause.
///
pub type Offset {
  NoOffset
  Offset(offset: Int)
}

/// Create a new offset clause.
///
pub fn offset_new(offset offst: Int) -> Offset {
  case offst > 0 {
    False -> NoOffset
    True -> Offset(offset: offst)
  }
}

fn offset_clause_apply(
  prepared_statement prp_stm: PreparedStatement,
  offset offst: Offset,
) -> PreparedStatement {
  case offst {
    NoOffset -> ""
    Offset(offset: offst) -> " OFFSET " <> offst |> int.to_string
  }
  |> prepared_statement.append_sql(prp_stm, _)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Epilog                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Used to add a trailing SQL statement to the query.
///
/// Epilog allows to append raw SQL to the end of queries.
///
/// One should NEVER put raw user data into the epilog.
///
pub type Epilog {
  NoEpilog
  // TODO v3 convert to List(String)
  Epilog(string: String)
}

/// Apply the epilog to the prepared statement.
///
pub fn epilog_apply(
  prepared_statement prp_stm: PreparedStatement,
  epilog eplg: Epilog,
) -> PreparedStatement {
  case eplg {
    NoEpilog -> prp_stm
    Epilog(string: eplgs) -> prp_stm |> prepared_statement.append_sql(eplgs)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Comment                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

/// Used to add a trailing SQL comment to a query.
///
pub type Comment {
  NoComment
  // TODO v3 convert to List(String)
  Comment(string: String)
}

/// Apply the comment to the prepared statement.
///
pub fn comment_apply(
  prepared_statement prp_stm: PreparedStatement,
  comment cmmnt: Comment,
) -> PreparedStatement {
  case cmmnt {
    NoComment -> prp_stm
    Comment(string: cmmnt) ->
      case cmmnt |> string.contains("\n") || cmmnt |> string.contains("\r") {
        True ->
          prp_stm
          |> prepared_statement.append_sql(
            " /* "
            <> cmmnt
            |> string.trim
            |> string.replace(each: "*/", with: "* /")
            |> string.replace(each: "/*", with: "/ *")
            <> " */",
          )
        False ->
          prp_stm
          |> prepared_statement.append_sql(" -- " <> cmmnt |> string.trim)
      }
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Fragment                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

// TODO v3 Create injection checker, something like:
//
// `gleam run --module cake/sql-injection-check -- ./src`
//
// This could parse the gleam source and find spots where fragments are used
// and check if the inserted values are gleam constants only.
//
// This solution could potentially be extended to a Literal type that where a
// function takes a Literal the wrapped value (LiteralString, etc) must be a
// gleam constant - this could work across this whole query builder.

/// Fragments are used to insert raw SQL into the query.
///
/// NOTICE: Injecting input data into fragments is only safe when using
/// `FragmentPrepared` and only using literal strings in the `fragment` field.
///
/// As a strategy it is recommended to ALWAYS USE MODULE CONSTANTS for
/// any `fragment`-field string.
///
pub type Fragment {
  FragmentLiteral(fragment: String)
  FragmentPrepared(fragment: String, params: List(Param))
}

/// Use to mark the position where a parameter should be inserted into for a
/// fragment with a prepared parameter.
///
pub const fragment_placeholder_grapheme = "$"

/// Splits a fragment string into a list of placeholders and other strings.
///
/// Splits something like `GREATER($, $)` into
/// `["GREATER(", "$", ", ", "$", ")"]`.
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
      // If Encountering anything else but there isn't anything yet, we want to
      // add it as a single item.
      False, [] -> [grapheme]
      // If the previous item matches a placeholder, we don't want to append
      // to it, because we want placeholders to exist as separat single items.
      False, [x, ..] if x == fragment_placeholder_grapheme -> [grapheme, ..acc]
      // In any other case we can just append to the previous item.
      False, [x, ..xs] -> [x <> grapheme, ..xs]
    }
  })
  |> list.reverse
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
      // This is likely a user error that cannot be catched by the type system,
      // but instead of crashing we do the best we can:
      //
      // For the user ´fragment.prepared()` should be used with caution and will
      // warn about the mismatch at runtime.
      let prms = case frgmt_plchldr_count |> int.compare(with: prms_count) {
        order.Eq -> prms
        order.Lt -> {
          // If there are more params than placeholders, we take the first `n`
          // params where `n` is the number of placeholders, and discard the
          // rest.
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
          let assert Ok(last_item) = prms |> list.last
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
                // Pop one of the list, and use it as the next parameter value.
                // This is safe because we have already checked that the list is
                // not empty.
                let assert [prm, ..rest_prms] = acc.1
                let new_prp_stm =
                  new_prp_stm |> prepared_statement.append_param(prm)

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

/// Count the number of placeholders in a list of string fragments.
///
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
