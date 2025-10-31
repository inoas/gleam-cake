//// Contains types and composition functions to build _read queries_.
////
//// _Read queries_ are in essence SELECT and combined queries such as `UNION`,
//// `UNION ALL`, `INTERSECT`, 'EXCEPT', etc. which combine multiple `SELECT`
//// queries into one query.
////
//// ## Notice
////
//// The included types are all non-opaque public, so that you _CAN_ build
//// whatever you want in user-land code, however the whole module is internal
//// because you _SHOULD NOT_ build queries based on raw types manually.
////
//// Because the likelihood of creating invalid queries is much higher than using
//// the interface modules found in `cake/*`.
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

import cake/internal/dialect.{type Dialect, Maria, Mysql, Postgres, Sqlite}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/param.{type Param, StringParam}
import gleam/int
import gleam/list
import gleam/order
import gleam/string

/// Used by cake internally to prefix computed aliases.
///
pub const computed_alias_prefix = "__cake_computed_alias_"

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Read Query                                                               │
// └───────────────────────────────────────────────────────────────────────────┘

/// A read query can be either a `SELECT` query or a combined query.
///
/// A combined query is a query that combines multiple `SELECT` queries into one
/// query using `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT`, etc.
///
pub type ReadQuery {
  SelectQuery(query: Select)
  CombinedQuery(query: Combined)
}

/// Creates a prepared statement from a query.
///
pub fn to_prepared_statement(
  query query: ReadQuery,
  placeholder_base placeholder_base: String,
  dialect dialect: Dialect,
) -> PreparedStatement {
  placeholder_base
  |> prepared_statement.new(dialect:)
  |> apply(query:)
}

/// Applies a query to a prepared statement.
///
pub fn apply(
  prepared_statement prepared_statement: PreparedStatement,
  query query: ReadQuery,
) -> PreparedStatement {
  case query {
    SelectQuery(query: select_query) ->
      prepared_statement |> select_builder(select_query:)
    CombinedQuery(query: combined_query) ->
      prepared_statement |> combined_builder(combined_query:)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Combined (UNION, UNION ALL, etc)                                         │
// └───────────────────────────────────────────────────────────────────────────┘

fn combined_builder(
  prepared_statement prepared_statement: PreparedStatement,
  combined_query combined_query: Combined,
) -> PreparedStatement {
  prepared_statement
  |> combined_clause_apply(combined_query:)
  |> order_by_clause_apply(combined_query.order_by)
  |> limit_clause_apply(combined_query.limit)
  |> offset_clause_apply(combined_query.offset)
  |> epilog_apply(combined_query.epilog)
  |> comment_apply(combined_query.comment)
}

/// Applies a combined query to a prepared statement.
///
pub fn combined_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  combined_query query: Combined,
) -> PreparedStatement {
  let sql_command = case query.kind {
    UnionDistinct -> "UNION"
    UnionAll -> "UNION ALL"
    ExceptDistinct -> "EXCEPT"
    ExceptAll -> "EXCEPT ALL"
    IntersectDistinct -> "INTERSECT"
    IntersectAll -> "INTERSECT ALL"
  }

  // `LIMIT`, `OFFSET` and `ORDER BY` is non-standard SQL within queries nested
  // in UNION and its siblings (combined queries) but they do work on
  // 🐘PostgreSQL, 🦭MariaDB and 🐬MySQL out of the box,
  // see <https://github.com/diesel-rs/diesel/issues/3151>.
  //
  // For 🪶SQLite we are wrapping them in sub-queries, like so:
  //
  // ```sql
  // SELECT * FROM (SELECT * FROM cats LIMIT 3) AS c1
  // UNION ALL
  // SELECT * FROM (SELECT * FROM cats OFFSET 2) AS c2
  // LIMIT 1
  // ```

  let open_nested_query = fn(prepared_statement: PreparedStatement) -> PreparedStatement {
    case prepared_statement |> prepared_statement.get_dialect {
      Sqlite ->
        prepared_statement |> prepared_statement.append_sql("SELECT * FROM (")
      _ -> prepared_statement |> prepared_statement.append_sql("(")
    }
  }

  let close_nested_query = fn(
    prepared_statement: PreparedStatement,
    nested_index: Int,
  ) -> PreparedStatement {
    case prepared_statement |> prepared_statement.get_dialect {
      Sqlite ->
        prepared_statement
        |> prepared_statement.append_sql(
          ") AS " <> computed_alias_prefix <> nested_index |> int.to_string,
        )
      _ -> prepared_statement |> prepared_statement.append_sql(")")
    }
  }

  let prepared_statement = prepared_statement |> open_nested_query
  let #(new_prepared_statement, nested_index) =
    query.queries
    |> list.fold(
      #(prepared_statement, 0),
      fn(acc: #(PreparedStatement, Int), query: Select) -> #(
        PreparedStatement,
        Int,
      ) {
        let #(new_prepared_statement, nested_index) = acc
        case new_prepared_statement == prepared_statement {
          True -> #(
            new_prepared_statement |> select_builder(query),
            nested_index,
          )
          False -> {
            let nested_index = nested_index + 1
            let new_prepared_statement =
              new_prepared_statement
              |> close_nested_query(nested_index)
              |> prepared_statement.append_sql(" " <> sql_command <> " ")
              |> open_nested_query
              |> select_builder(query)

            #(new_prepared_statement, nested_index)
          }
        }
      },
    )
  new_prepared_statement |> close_nested_query(nested_index + 1)
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

/// NOTICE: 🪶SQLite does not support `EXCEPT ALL` (`ExceptAll`) nor
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
  kind kind: CombinedQueryKind,
  queries queries: List(Select),
) -> Combined {
  queries
  |> Combined(
    kind:,
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
  query query: Combined,
  by order_by: OrderBy,
  append append: Bool,
) -> Combined {
  case append {
    True ->
      Combined(
        ..query,
        order_by: query.order_by |> order_by_append(new_order_by: order_by),
      )
    False -> Combined(..query, order_by:)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Select                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

fn select_builder(
  prepared_statement prepared_statement: PreparedStatement,
  select_query query: Select,
) -> PreparedStatement {
  prepared_statement
  |> select_clause_apply(query.kind, query.select)
  |> from_clause_apply(query.from)
  |> join_clause_apply(query.join)
  |> where_clause_apply(query.where)
  |> group_by_clause_apply(query.group_by)
  |> having_clause_apply(query.having)
  |> order_by_clause_apply(query.order_by)
  |> limit_clause_apply(query.limit)
  |> offset_clause_apply(query.offset)
  |> epilog_apply(query.epilog)
  |> comment_apply(query.comment)
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
  select_query query: Select,
  by order_by: OrderBy,
  append append: Bool,
) -> Select {
  case append {
    True ->
      Select(
        ..query,
        order_by: query.order_by |> order_by_append(new_order_by: order_by),
      )
    False -> Select(..query, order_by:)
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
  Selects(select_values: List(SelectValue))
}

/// A value that can be selected in a `SELECT` query.
/// It can be a column, a parameter, a fragment, or a value with an alias.
///
/// TODO v2 Investigate -> probably makes no sense to have params/values in
/// SELECT?
///
pub type SelectValue {
  SelectColumn(column: String)
  // TODO v2 Investigate -> probably makes no sense to have params in SELECT?
  SelectParam(param: Param)
  SelectFragment(fragment: Fragment)
  SelectAlias(value: SelectValue, alias: String)
}

fn select_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  kind kind: SelectKind,
  selects selects: Selects,
) -> PreparedStatement {
  let select_command = case kind {
    SelectAll -> "SELECT"
    SelectDistinct -> "SELECT DISTINCT"
  }
  case selects {
    NoSelects ->
      prepared_statement
      |> prepared_statement.append_sql(select_command <> " *")
    Selects(select_vs) -> {
      case select_vs {
        [] -> prepared_statement
        vs -> {
          let prepared_statement =
            prepared_statement
            |> prepared_statement.append_sql(select_command <> " ")
          vs
          |> list.fold(
            prepared_statement,
            fn(new_prepared_statement: PreparedStatement, v: SelectValue) -> PreparedStatement {
              case new_prepared_statement == prepared_statement {
                True -> new_prepared_statement |> select_value_apply(v)
                False ->
                  new_prepared_statement
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
  prepared_statement prepared_statement: PreparedStatement,
  value v: SelectValue,
) -> PreparedStatement {
  case v {
    SelectColumn(col) ->
      prepared_statement |> prepared_statement.append_sql(col)
    SelectParam(param) ->
      prepared_statement |> prepared_statement.append_param(param)
    SelectFragment(fragment) -> prepared_statement |> fragment_apply(fragment)
    SelectAlias(v, alias) ->
      prepared_statement
      |> select_value_apply(v)
      |> prepared_statement.append_sql(" AS " <> alias)
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
  // TODO v2 FromSubQuery(sub_queries: List(#(sub_query: ReadQuery, alias: String)))
  // interfacing functions should exist to specify a single item or a list
  FromTable(name: String)
  FromSubQuery(query: ReadQuery, alias: String)
}

/// Applies the `FROM` clause to a prepared statement by appending the SQL code.
///
pub fn from_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  from frm: From,
) -> PreparedStatement {
  case frm {
    NoFrom -> prepared_statement
    FromTable(tbl_nm) ->
      prepared_statement |> prepared_statement.append_sql(" FROM " <> tbl_nm)
    FromSubQuery(query, als) ->
      prepared_statement
      |> prepared_statement.append_sql(" FROM (")
      |> apply(query)
      |> prepared_statement.append_sql(") AS " <> als)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Where                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Describes the `WHERE` clause of SQL queries.
///
/// NOTICE: 🪶SQLite does _not_ support:
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
    query: ReadQuery,
  )
  WhereAllOfSubQuery(
    value_a: WhereValue,
    operator: WhereComparisonOperator,
    query: ReadQuery,
  )
  WhereIn(value: WhereValue, values: List(WhereValue))
  WhereExistsInSubQuery(query: ReadQuery)
  WhereBetween(value_a: WhereValue, value_b: WhereValue, value_c: WhereValue)
  WhereLike(value: WhereValue, pattern: String)
  WhereILike(value: WhereValue, pattern: String)
  WhereSimilarTo(value: WhereValue, pattern: String, escape_char: String)
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
  WhereSubQueryValue(query: ReadQuery)
}

/// Applies the `WHERE` clause to a prepared statement by appending the SQL
/// code.
///
pub fn where_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prepared_statement
    _ ->
      prepared_statement
      |> prepared_statement.append_sql(" WHERE ")
      |> where_apply(wh)
  }
}

fn having_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prepared_statement
    _ ->
      prepared_statement
      |> prepared_statement.append_sql(" HAVING ")
      |> where_apply(wh)
  }
}

fn where_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where wh: Where,
) -> PreparedStatement {
  case wh {
    NoWhere -> prepared_statement
    AndWhere(whs) ->
      prepared_statement |> where_logical_operator_apply("AND", whs, False)
    OrWhere(whs) ->
      prepared_statement |> where_logical_operator_apply("OR", whs, True)
    XorWhere(whs) -> prepared_statement |> where_xor_apply(whs)
    NotWhere(wh) ->
      prepared_statement
      |> prepared_statement.append_sql("NOT(")
      |> where_apply(wh)
      |> prepared_statement.append_sql(")")
    WhereIsBool(val, True) ->
      prepared_statement |> where_literal_apply(val, "IS TRUE")
    WhereIsBool(val, False) ->
      prepared_statement |> where_literal_apply(val, "IS FALSE")
    WhereIsNotBool(val, True) ->
      prepared_statement |> where_literal_apply(val, "IS NOT TRUE")
    WhereIsNotBool(val, False) ->
      prepared_statement |> where_literal_apply(val, "IS NOT FALSE")
    WhereIsNull(val) ->
      prepared_statement |> where_literal_apply(val, "IS NULL")
    WhereIsNotNull(val) ->
      prepared_statement |> where_literal_apply(val, "IS NOT NULL")
    WhereComparison(val_a, Equal, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, "=", val_b)
    WhereComparison(val_a, Greater, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, ">", val_b)
    WhereComparison(val_a, GreaterOrEqual, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, ">=", val_b)
    WhereComparison(val_a, Lower, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, "<", val_b)
    WhereComparison(val_a, LowerOrEqual, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, "<=", val_b)
    WhereComparison(val_a, Unequal, val_b) ->
      prepared_statement |> where_comparison_apply(val_a, "<>", val_b)
    WhereAnyOfSubQuery(val, Equal, query) ->
      prepared_statement
      |> where_literal_apply(val, "= ANY")
      |> where_sub_query_apply(query)
    WhereAnyOfSubQuery(val, Greater, query) ->
      prepared_statement
      |> where_literal_apply(val, "> ANY")
      |> where_sub_query_apply(query)
    WhereAnyOfSubQuery(val, GreaterOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(val, ">= ANY")
      |> where_sub_query_apply(query)
    WhereAnyOfSubQuery(val, Lower, query) ->
      prepared_statement
      |> where_literal_apply(val, "< ANY")
      |> where_sub_query_apply(query)
    WhereAnyOfSubQuery(val, LowerOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(val, "<= ANY")
      |> where_sub_query_apply(query)
    WhereAnyOfSubQuery(val, Unequal, query) ->
      prepared_statement
      |> where_literal_apply(val, "<> ANY")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, Equal, query) ->
      prepared_statement
      |> where_literal_apply(val, "= ALL")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, Greater, query) ->
      prepared_statement
      |> where_literal_apply(val, "> ALL")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, GreaterOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(val, ">= ALL")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, Lower, query) ->
      prepared_statement
      |> where_literal_apply(val, "< ALL")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, LowerOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(val, "<= ALL")
      |> where_sub_query_apply(query)
    WhereAllOfSubQuery(val, Unequal, query) ->
      prepared_statement
      |> where_literal_apply(val, "<> ALL")
      |> where_sub_query_apply(query)
    WhereBetween(val_a, val_b, val_c) ->
      prepared_statement |> where_between_apply(val_a, val_b, val_c)
    WhereIn(val, vals) ->
      prepared_statement |> where_value_in_values_apply(val, vals)
    WhereExistsInSubQuery(query) ->
      prepared_statement
      |> prepared_statement.append_sql(" EXISTS ")
      |> where_sub_query_apply(query)
    WhereLike(val, param) ->
      prepared_statement
      |> where_comparison_apply(
        val,
        "LIKE",
        param |> StringParam |> WhereParamValue,
      )
    WhereILike(value: val, pattern: param) ->
      prepared_statement
      |> where_comparison_apply(
        val,
        "ILIKE",
        param |> StringParam |> WhereParamValue,
      )
    WhereSimilarTo(value: val, pattern: param, escape_char: ecp_chr) ->
      prepared_statement
      |> where_comparison_apply(
        val,
        "SIMILAR TO",
        param |> StringParam |> WhereParamValue,
      )
      |> prepared_statement.append_sql(" ESCAPE '" <> ecp_chr <> "'")
    WhereFragment(fragment) -> prepared_statement |> fragment_apply(fragment)
  }
}

fn where_literal_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value v: WhereValue,
  literal lt: String,
) -> PreparedStatement {
  case v {
    WhereColumnValue(col) ->
      prepared_statement |> prepared_statement.append_sql(col <> " " <> lt)
    WhereParamValue(param) ->
      prepared_statement |> prepared_statement.append_param(param)
    WhereFragmentValue(fragment: fragment) ->
      prepared_statement
      |> fragment_apply(fragment)
      |> prepared_statement.append_sql(" " <> lt)
    WhereSubQueryValue(query) ->
      prepared_statement
      |> where_sub_query_apply(query)
      |> prepared_statement.append_sql(" " <> lt)
  }
}

fn where_comparison_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value_a val_a: WhereValue,
  operator oprtr: String,
  value_b val_b: WhereValue,
) -> PreparedStatement {
  case val_a, val_b {
    WhereColumnValue(col_a), WhereColumnValue(col_b) ->
      prepared_statement
      |> where_string_apply(col_a <> " " <> oprtr <> " " <> col_b)
    WhereColumnValue(col), WhereParamValue(param) ->
      prepared_statement
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> where_param_apply(param)
    WhereParamValue(param), WhereColumnValue(col) ->
      prepared_statement
      |> where_param_apply(param)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereParamValue(param_a), WhereParamValue(param_b) ->
      prepared_statement
      |> where_param_apply(param_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(param_b)
    WhereFragmentValue(fragment), WhereColumnValue(col) ->
      prepared_statement
      |> fragment_apply(fragment)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereColumnValue(col), WhereFragmentValue(fragment) ->
      prepared_statement
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> fragment_apply(fragment)
    WhereFragmentValue(fragment), WhereParamValue(param) ->
      prepared_statement
      |> fragment_apply(fragment)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(param)
    WhereParamValue(param), WhereFragmentValue(fragment) ->
      prepared_statement
      |> where_param_apply(param)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(fragment)
    WhereFragmentValue(fragment_a), WhereFragmentValue(fragment_b) ->
      prepared_statement
      |> fragment_apply(fragment_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(fragment_b)
    WhereSubQueryValue(query_a), WhereSubQueryValue(query_b) ->
      prepared_statement
      |> where_sub_query_apply(query_a)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(query_b)
    WhereColumnValue(col), WhereSubQueryValue(query) ->
      prepared_statement
      |> where_string_apply(col <> " " <> oprtr <> " ")
      |> where_sub_query_apply(query)
    WhereSubQueryValue(query), WhereColumnValue(col) ->
      prepared_statement
      |> where_sub_query_apply(query)
      |> where_string_apply(" " <> oprtr <> " " <> col)
    WhereParamValue(param), WhereSubQueryValue(query) ->
      prepared_statement
      |> where_param_apply(param)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(query)
    WhereSubQueryValue(query), WhereParamValue(param) ->
      prepared_statement
      |> where_sub_query_apply(query)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_param_apply(param)
    WhereFragmentValue(fragment), WhereSubQueryValue(query) ->
      prepared_statement
      |> fragment_apply(fragment)
      |> where_string_apply(" " <> oprtr <> " ")
      |> where_sub_query_apply(query)
    WhereSubQueryValue(query), WhereFragmentValue(fragment) ->
      prepared_statement
      |> where_sub_query_apply(query)
      |> where_string_apply(" " <> oprtr <> " ")
      |> fragment_apply(fragment)
  }
}

fn where_string_apply(
  prepared_statement prepared_statement: PreparedStatement,
  string s: String,
) -> PreparedStatement {
  prepared_statement |> prepared_statement.append_sql(s)
}

fn where_param_apply(
  prepared_statement prepared_statement: PreparedStatement,
  param param: Param,
) -> PreparedStatement {
  prepared_statement |> prepared_statement.append_param(param)
}

fn where_sub_query_apply(
  prepared_statement prepared_statement: PreparedStatement,
  sub_query query: ReadQuery,
) -> PreparedStatement {
  prepared_statement
  |> prepared_statement.append_sql("(")
  |> apply(query)
  |> prepared_statement.append_sql(")")
}

fn where_logical_operator_apply(
  prepared_statement prepared_statement: PreparedStatement,
  operator oprtr: String,
  where whs: List(Where),
  wrap_in_parentheses wrp_prns: Bool,
) -> PreparedStatement {
  let prepared_statement = case wrp_prns {
    True -> prepared_statement |> prepared_statement.append_sql("(")
    False -> prepared_statement
  }

  let prepared_statement =
    whs
    |> list.fold(
      prepared_statement,
      fn(new_prepared_statement: PreparedStatement, wh: Where) -> PreparedStatement {
        case new_prepared_statement == prepared_statement {
          True -> new_prepared_statement |> where_apply(wh)
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql(" " <> oprtr <> " ")
            |> where_apply(wh)
        }
      },
    )

  let prepared_statement = case wrp_prns {
    True -> prepared_statement |> prepared_statement.append_sql(")")
    False -> prepared_statement
  }

  prepared_statement
}

fn where_xor_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where whs: List(Where),
) -> PreparedStatement {
  case prepared_statement |> prepared_statement.get_dialect {
    Postgres | Sqlite -> custom_where_xor_apply(prepared_statement, whs)
    Maria | Mysql -> vanilla_where_xor_apply(prepared_statement, whs)
  }
}

fn custom_where_xor_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where whs: List(Where),
) -> PreparedStatement {
  let xor_idxs = whs |> list.length |> int.subtract(1) |> list.range(0, _)

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("(")

  let prepared_statement =
    xor_idxs
    |> list.fold(
      prepared_statement,
      fn(new_prepared_statement: PreparedStatement, xor_idx: Int) -> PreparedStatement {
        let new_prepared_statement = case
          new_prepared_statement == prepared_statement
        {
          True -> new_prepared_statement
          False ->
            new_prepared_statement |> prepared_statement.append_sql(") OR (")
        }

        let #(new_prepared_statement, _last_wh_idx) =
          whs
          |> list.fold(
            #(new_prepared_statement, 0),
            fn(acc: #(PreparedStatement, Int), wh: Where) -> #(
              PreparedStatement,
              Int,
            ) {
              let #(new_prepared_statement_per_xor, wh_idx) = acc
              let new_prepared_statement_per_xor = case
                wh_idx == xor_idx,
                wh_idx
              {
                True, 0 -> new_prepared_statement_per_xor |> where_apply(wh)

                True, _gt_0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql(" AND (")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
                False, 0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql("NOT(")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
                False, _gt_0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql(" AND NOT(")
                  |> where_apply(wh)
                  |> prepared_statement.append_sql(")")
              }
              #(new_prepared_statement_per_xor, wh_idx + 1)
            },
          )

        new_prepared_statement
      },
    )

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(")")

  prepared_statement
}

fn vanilla_where_xor_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where whs: List(Where),
) -> PreparedStatement {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("(")

  whs
  |> list.fold(
    prepared_statement,
    fn(new_prepared_statement: PreparedStatement, wh: Where) -> PreparedStatement {
      case new_prepared_statement == prepared_statement {
        True -> new_prepared_statement |> where_apply(wh)
        False ->
          new_prepared_statement
          |> prepared_statement.append_sql(" XOR ")
          |> where_apply(wh)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_value_in_values_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value val: WhereValue,
  parameters params: List(WhereValue),
) -> PreparedStatement {
  let prepared_statement =
    case val {
      WhereColumnValue(col) ->
        prepared_statement |> prepared_statement.append_sql(col)
      WhereParamValue(param) ->
        prepared_statement |> prepared_statement.append_param(param)
      WhereFragmentValue(fragment) ->
        prepared_statement |> fragment_apply(fragment)
      WhereSubQueryValue(query) ->
        prepared_statement |> where_sub_query_apply(query)
    }
    |> prepared_statement.append_sql(" IN (")

  params
  |> list.fold(
    prepared_statement,
    fn(new_prepared_statement: PreparedStatement, v: WhereValue) -> PreparedStatement {
      case v {
        WhereColumnValue(col) ->
          case new_prepared_statement == prepared_statement {
            True -> new_prepared_statement |> prepared_statement.append_sql(col)
            False ->
              new_prepared_statement
              |> prepared_statement.append_sql(", " <> col)
          }
        WhereParamValue(param) ->
          case new_prepared_statement == prepared_statement {
            True -> ""
            False -> ", "
          }
          |> prepared_statement.append_sql(new_prepared_statement, _)
          |> prepared_statement.append_param(param)
        WhereFragmentValue(fragment) ->
          prepared_statement |> fragment_apply(fragment)
        WhereSubQueryValue(query) ->
          prepared_statement |> where_sub_query_apply(query)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_between_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value_a val_a: WhereValue,
  value_b val_b: WhereValue,
  value_c val_c: WhereValue,
) -> PreparedStatement {
  let prepared_statement = case val_a {
    WhereColumnValue(col) ->
      prepared_statement |> prepared_statement.append_sql(col)
    WhereParamValue(param) ->
      prepared_statement |> prepared_statement.append_param(param)
    WhereFragmentValue(fragment) ->
      prepared_statement |> fragment_apply(fragment)
    WhereSubQueryValue(query) ->
      prepared_statement |> where_sub_query_apply(query)
  }

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" BETWEEN ")

  let prepared_statement = case val_b {
    WhereColumnValue(col) ->
      prepared_statement |> prepared_statement.append_sql(col)
    WhereParamValue(param) ->
      prepared_statement |> prepared_statement.append_param(param)
    WhereFragmentValue(fragment) ->
      prepared_statement |> fragment_apply(fragment)
    WhereSubQueryValue(query) ->
      prepared_statement |> where_sub_query_apply(query)
  }

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" AND ")

  let prepared_statement = case val_c {
    WhereColumnValue(col) ->
      prepared_statement |> prepared_statement.append_sql(col)
    WhereParamValue(param) ->
      prepared_statement |> prepared_statement.append_param(param)
    WhereFragmentValue(fragment) ->
      prepared_statement |> fragment_apply(fragment)
    WhereSubQueryValue(query) ->
      prepared_statement |> where_sub_query_apply(query)
  }

  prepared_statement
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
  prepared_statement prepared_statement: PreparedStatement,
  group_by grpb: GroupBy,
) -> PreparedStatement {
  case grpb {
    NoGroupBy -> prepared_statement
    GroupBy(grpbs) ->
      prepared_statement
      |> prepared_statement.append_sql(" GROUP BY ")
      |> group_by_apply(grpbs)
  }
}

fn group_by_apply(
  prepared_statement prepared_statement: PreparedStatement,
  group_bys grpbs: List(String),
) -> PreparedStatement {
  case grpbs {
    [] -> prepared_statement
    _ ->
      grpbs
      |> list.fold(
        prepared_statement,
        fn(new_prepared_statement: PreparedStatement, s: String) -> PreparedStatement {
          case new_prepared_statement == prepared_statement {
            True -> new_prepared_statement |> prepared_statement.append_sql(s)
            False ->
              new_prepared_statement |> prepared_statement.append_sql(", " <> s)
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

/// The join target can be either a table or a sub-query.
///
pub type JoinTarget {
  JoinTable(table: String)
  JoinSubQuery(query: ReadQuery)
}

/// A Join can be one of:
///
/// - `InnerJoin`: `INNER JOIN`
/// - `LeftJoin`: `LEFT JOIN`
/// - `RightJoin`: `RIGHT JOIN`
/// - `FullJoin`: `FULL JOIN`
/// - `CrossJoin`: `CROSS JOIN`
///
/// as well as:
///
/// - `InnerJoinLateralOnTrue`: `INNER JOIN LATERAL ... ON TRUE`
/// - `LeftJoinLateralOnTrue`: `LEFT JOIN LATERAL ... ON TRUE`
/// - `CrossJoinLateral`: `CROSS JOIN LATERAL`
///
pub type Join {
  InnerJoin(with: JoinTarget, alias: String, on: Where)
  InnerJoinLateralOnTrue(with: JoinTarget, alias: String)
  LeftJoin(with: JoinTarget, alias: String, on: Where)
  LeftJoinLateralOnTrue(with: JoinTarget, alias: String)
  RightJoin(with: JoinTarget, alias: String, on: Where)
  FullJoin(with: JoinTarget, alias: String, on: Where)
  CrossJoin(with: JoinTarget, alias: String)
  CrossJoinLateral(with: JoinTarget, alias: String)
}

/// Apply join clauses to prepared statement.
///
pub fn join_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  joins jns: Joins,
) -> PreparedStatement {
  case jns {
    Joins(jns) -> {
      jns
      |> list.fold(
        prepared_statement,
        fn(new_prepared_statement: PreparedStatement, jn: Join) -> PreparedStatement {
          let join_command_apply = fn(
            new_prepared_statement: PreparedStatement,
            sql_command: String,
          ) -> PreparedStatement {
            new_prepared_statement
            |> prepared_statement.append_sql(" " <> sql_command <> " ")
            |> join_apply(jn)
          }

          let on_apply = fn(
            new_prepared_statement: PreparedStatement,
            on: Where,
          ) -> PreparedStatement {
            new_prepared_statement
            |> prepared_statement.append_sql(" ON ")
            |> where_apply(on)
          }

          case jn {
            InnerJoin(_, _, on: on) ->
              new_prepared_statement
              |> join_command_apply("INNER JOIN")
              |> on_apply(on)
            InnerJoinLateralOnTrue(_, _) ->
              new_prepared_statement
              |> join_command_apply("INNER JOIN LATERAL")
              |> prepared_statement.append_sql(" ON TRUE")
            LeftJoin(_, _, on: on) ->
              new_prepared_statement
              |> join_command_apply("LEFT OUTER JOIN")
              |> on_apply(on)
            LeftJoinLateralOnTrue(_, _) ->
              new_prepared_statement
              |> join_command_apply("LEFT JOIN LATERAL")
              |> prepared_statement.append_sql(" ON TRUE")
            RightJoin(_, _, on: on) ->
              new_prepared_statement
              |> join_command_apply("RIGHT OUTER JOIN")
              |> on_apply(on)
            FullJoin(_, _, on: on) ->
              new_prepared_statement
              |> join_command_apply("FULL OUTER JOIN")
              |> on_apply(on)
            CrossJoin(_, _) ->
              new_prepared_statement |> join_command_apply("CROSS JOIN")
            CrossJoinLateral(_, _) ->
              new_prepared_statement |> join_command_apply("CROSS JOIN LATERAL")
          }
        },
      )
    }
    NoJoins -> prepared_statement
  }
}

pub fn join_apply(
  prepared_statement prepared_statement: PreparedStatement,
  join jn: Join,
) -> PreparedStatement {
  case jn.with {
    JoinTable(table: tbl) ->
      prepared_statement
      |> prepared_statement.append_sql(tbl <> " AS " <> jn.alias)
    JoinSubQuery(query: query) ->
      prepared_statement
      |> prepared_statement.append_sql("(")
      |> apply(query)
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
/// - `AscNullsFirst` - Ascending order with nulls first, supported by
///   🦭MariaDB nor 🐬MySQL
/// - `AscNullsLast` - Ascending order with nulls last, supported by
///   🦭MariaDB nor 🐬MySQL
/// - `Desc` - Descending order
/// - `DescNullsFirst` - Descending order with nulls first, supported by
///    🦭MariaDB nor 🐬MySQL
/// - `DescNullsLast` - Descending order with nulls last, supported by
///    🦭MariaDB nor 🐬MySQL
///
pub type OrderByDirection {
  Asc
  AscNullsFirst
  AscNullsLast
  Desc
  DescNullsFirst
  DescNullsLast
}

fn order_by_append(
  order_by order_by: OrderBy,
  new_order_by new_order_by: OrderBy,
) -> OrderBy {
  case order_by {
    NoOrderBy -> new_order_by
    OrderBy(order_by_items) -> {
      let new_order_by_items = case new_order_by {
        NoOrderBy -> []
        OrderBy(new_order_by) -> new_order_by
      }
      let new_order_by_item = case order_by_items {
        [] -> new_order_by_items
        _ -> order_by_items |> list.append(new_order_by_items)
      }
      case new_order_by_item {
        [] -> NoOrderBy
        _ -> OrderBy(new_order_by_item)
      }
    }
  }
}

fn order_by_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  order_by order_by: OrderBy,
) -> PreparedStatement {
  case order_by {
    NoOrderBy -> prepared_statement
    OrderBy(order_bys) -> {
      case order_bys {
        [] -> prepared_statement
        vs -> {
          let prepared_statement =
            prepared_statement |> prepared_statement.append_sql(" ORDER BY ")
          vs
          |> list.fold(
            prepared_statement,
            fn(new_prepared_statement: PreparedStatement, v: OrderByValue) -> PreparedStatement {
              case new_prepared_statement == prepared_statement {
                True -> new_prepared_statement |> order_by_value_apply(v)
                False ->
                  new_prepared_statement
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
  prepared_statement prepared_statement: PreparedStatement,
  value v: OrderByValue,
) -> PreparedStatement {
  case v {
    OrderByColumn(col, dir) ->
      prepared_statement
      |> prepared_statement.append_sql(col)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
    OrderByFragment(fragment, dir) ->
      prepared_statement
      |> fragment_apply(fragment)
      |> prepared_statement.append_sql(" " <> dir |> order_by_direction_to_sql)
  }
}

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` or `NULLS LAST`.
/// Instead, `NULL`s are considered to have the lowest value, thus ordering in
/// `DESC` order will see the `NULL`s appearing last. To force `NULL`s to be
/// regarded as highest values, see
/// <https://mariadb.com/kb/en/null-values/#ordering>.
///
fn order_by_direction_to_sql(
  order_by_direction order_byd: OrderByDirection,
) -> String {
  case order_byd {
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
  prepared_statement prepared_statement: PreparedStatement,
  limit lmt: Limit,
) -> PreparedStatement {
  case lmt {
    NoLimit -> ""
    Limit(limit: lmt) -> " LIMIT " <> lmt |> int.to_string
  }
  |> prepared_statement.append_sql(prepared_statement, _)
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
  prepared_statement prepared_statement: PreparedStatement,
  offset offst: Offset,
) -> PreparedStatement {
  case offst {
    NoOffset -> ""
    Offset(offset: offst) -> " OFFSET " <> offst |> int.to_string
  }
  |> prepared_statement.append_sql(prepared_statement, _)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Epilog                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Used to add a trailing SQL statement to the query.
///
/// `Epilog` allows to append raw SQL to the end of queries (an epilogue).
///
/// One should NEVER put raw user data into the `Epilog`.
///
pub type Epilog {
  NoEpilog
  // TODO v3 convert to List(String)
  Epilog(string: String)
}

/// Apply the epilog to the prepared statement.
///
pub fn epilog_apply(
  prepared_statement prepared_statement: PreparedStatement,
  epilog eplg: Epilog,
) -> PreparedStatement {
  case eplg {
    NoEpilog -> prepared_statement
    Epilog(string: eplgs) ->
      prepared_statement |> prepared_statement.append_sql(eplgs)
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
  prepared_statement prepared_statement: PreparedStatement,
  comment cmmnt: Comment,
) -> PreparedStatement {
  case cmmnt {
    NoComment -> prepared_statement
    Comment(string: cmmnt) ->
      case cmmnt |> string.contains("\n") || cmmnt |> string.contains("\r") {
        True ->
          prepared_statement
          |> prepared_statement.append_sql(
            " /* "
            <> cmmnt
            |> string.trim
            |> string.replace(each: "*/", with: "* /")
            |> string.replace(each: "/*", with: "/ *")
            <> " */",
          )
        False ->
          prepared_statement
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
  string_fragment str_fragment: String,
) -> List(String) {
  str_fragment
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
  prepared_statement prepared_statement: PreparedStatement,
  fragment fragment: Fragment,
) -> PreparedStatement {
  case fragment {
    FragmentLiteral(fragment: fragment) ->
      prepared_statement |> prepared_statement.append_sql(fragment)
    FragmentPrepared(fragment: fragment, params: []) ->
      // This is likely a user error and they meant `FragmentLiteral`
      // if they did not give any params.
      prepared_statement |> prepared_statement.append_sql(fragment)
    FragmentPrepared(fragment: fragment, params: params) -> {
      let fragments = fragment |> fragment_prepared_split_string
      let fragment_placeholder_count = fragments |> fragment_count_placeholders
      let params_count = params |> list.length

      // Fill up or reduce params to match the given number of placeholders
      // in the fragment.
      //
      // Param count not equalling fragement placeholder cound is likely a user
      // error that cannot be caught by the type system, but instead of crashing
      // we do the best we can:
      //
      // For the user ´fragment.prepared()` should be used with caution and will
      // warn about the mismatch at runtime.
      let params = case
        fragment_placeholder_count |> int.compare(with: params_count),
        params |> list.reverse
      {
        // Expected branch, no user error
        order.Eq, _ -> params
        // User error: Not enough fragments
        order.Lt, _ -> {
          // If there are more params than placeholders, we take the first `n`
          // params where `n` is the number of placeholders, and discard the
          // rest.
          let missing_placeholders = params_count - fragment_placeholder_count

          params |> list.take(missing_placeholders + 1)
        }
        // User error: Not enough params
        order.Gt, [last_item, ..] -> {
          // If there are more placeholders than params, we repeat the last
          // param until the number of placeholders is reached.
          let missing_params = fragment_placeholder_count - params_count
          let repeated_last_item = last_item |> list.repeat(missing_params)

          params |> list.append(repeated_last_item)
        }
        // User error: No params at all
        order.Gt, [] -> {
          []
        }
      }

      case fragments {
        // This branch should be unreachable at runtime,
        // because it makes little sense to use Fragments without supplying
        // them:
        [] -> prepared_statement
        // This branch should always run at runtime:
        fragments -> {
          let #(new_prepared_statement, _param_rest) =
            fragments
            |> list.fold(
              #(prepared_statement, params),
              fn(acc: #(PreparedStatement, List(Param)), fragment: String) -> #(
                PreparedStatement,
                List(Param),
              ) {
                let new_prepared_statement = acc.0
                let params = acc.1
                case fragment == fragment_placeholder_grapheme, params {
                  False, _ -> #(
                    new_prepared_statement
                      |> prepared_statement.append_sql(fragment),
                    params,
                  )
                  True, [param, ..rest_params] -> #(
                    new_prepared_statement
                      |> prepared_statement.append_param(param),
                    rest_params,
                  )
                  // This branch should be unreachable at runtime:
                  True, [] -> #(
                    new_prepared_statement
                      |> prepared_statement.append_sql(fragment),
                    [],
                  )
                }
              },
            )

          new_prepared_statement
        }
      }
    }
  }
}

/// Count the number of placeholders in a list of string fragments.
///
pub fn fragment_count_placeholders(
  string_fragments string_fragments: List(String),
) -> Int {
  string_fragments
  |> list.fold(0, fn(count: Int, s_fragment: String) -> Int {
    case s_fragment == fragment_placeholder_grapheme {
      True -> count + 1
      False -> count
    }
  })
}
