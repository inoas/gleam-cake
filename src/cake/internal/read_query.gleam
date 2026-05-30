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
// │ Read Query                                                                │
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
    SelectQuery(query:) -> prepared_statement |> select_builder(query:)
    CombinedQuery(query:) -> prepared_statement |> combined_builder(query:)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Combined (UNION, UNION ALL, etc)                                          │
// └───────────────────────────────────────────────────────────────────────────┘

fn combined_builder(
  prepared_statement prepared_statement: PreparedStatement,
  query query: Combined,
) -> PreparedStatement {
  prepared_statement
  |> combined_clause_apply(combined_query: query)
  |> order_by_clause_apply(order_by: query.order_by)
  |> limit_clause_apply(limit: query.limit)
  |> offset_clause_apply(offset: query.offset)
  |> epilog_apply(epilog: query.epilog)
  |> comment_apply(comment: query.comment)
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
        prepared_statement
        |> prepared_statement.append_sql("SELECT * FROM (")
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
          sql: ") AS " <> computed_alias_prefix <> nested_index |> int.to_string,
        )
      _ -> prepared_statement |> prepared_statement.append_sql(")")
    }
  }

  let prepared_statement = prepared_statement |> open_nested_query
  let #(new_prepared_statement, nested_index) =
    query.queries
    |> list.fold(
      from: #(prepared_statement, 0),
      with: fn(accumulator: #(PreparedStatement, Int), query: Select) -> #(
        PreparedStatement,
        Int,
      ) {
        let #(new_prepared_statement, nested_index) = accumulator
        case new_prepared_statement == prepared_statement {
          True -> #(
            new_prepared_statement |> select_builder(query:),
            nested_index,
          )
          False -> {
            let nested_index = nested_index + 1
            let new_prepared_statement =
              new_prepared_statement
              |> close_nested_query(nested_index)
              |> prepared_statement.append_sql(" " <> sql_command <> " ")
              |> open_nested_query
              |> select_builder(query:)

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
  order_by order_by: OrderBy,
  append append: Bool,
) -> Combined {
  case append {
    True ->
      Combined(..query, order_by: query.order_by |> order_by_append(order_by:))
    False -> Combined(..query, order_by:)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Select                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

fn select_builder(
  prepared_statement prepared_statement: PreparedStatement,
  query query: Select,
) -> PreparedStatement {
  prepared_statement
  |> select_clause_apply(kind: query.kind, selects: query.select)
  |> from_clause_apply(from: query.from)
  |> join_clause_apply(joins: query.join)
  |> where_clause_apply(where: query.where)
  |> group_by_clause_apply(group_by: query.group_by)
  |> having_clause_apply(where: query.having)
  |> order_by_clause_apply(order_by: query.order_by)
  |> limit_clause_apply(limit: query.limit)
  |> offset_clause_apply(offset: query.offset)
  |> epilog_apply(epilog: query.epilog)
  |> comment_apply(comment: query.comment)
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
  order_by order_by: OrderBy,
  append append: Bool,
) -> Select {
  case append {
    True ->
      Select(..query, order_by: query.order_by |> order_by_append(order_by:))
    False -> Select(..query, order_by:)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Selects                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declares the projection of a `SELECT` query.
///
/// If no columns are selected, all columns are returned, aka `SELECT *`.
///
pub type Selects {
  NoSelects
  Selects(values: List(SelectValue))
}

/// A value that can be selected in a `SELECT` query.
/// It can be a column, a parameter, a fragment, or a value with an alias.
///
/// TODO v2 Investigate -> probably makes no sense to have params/values in
/// SELECT?
///
pub type SelectValue {
  SelectColumn(name: String)
  // TODO v2 Investigate -> probably makes no sense to have params in SELECT?
  SelectParam(value: Param)
  SelectFragment(value: Fragment)
  SelectAlias(value: SelectValue, name: String)
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
    Selects(values:) -> {
      case values {
        [] -> prepared_statement
        vs -> {
          let prepared_statement =
            prepared_statement
            |> prepared_statement.append_sql(select_command <> " ")
          vs
          |> list.fold(
            from: prepared_statement,
            with: fn(
              new_prepared_statement: PreparedStatement,
              value: SelectValue,
            ) -> PreparedStatement {
              case new_prepared_statement == prepared_statement {
                True -> new_prepared_statement |> select_value_apply(value)
                False ->
                  new_prepared_statement
                  |> prepared_statement.append_sql(", ")
                  |> select_value_apply(value)
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
  value value: SelectValue,
) -> PreparedStatement {
  case value {
    SelectColumn(name:) ->
      prepared_statement |> prepared_statement.append_sql(name)
    SelectParam(value:) ->
      prepared_statement |> prepared_statement.append_param(value)
    SelectFragment(value:) ->
      prepared_statement |> fragment_apply(fragment: value)
    SelectAlias(value, name) ->
      prepared_statement
      |> select_value_apply(value:)
      |> prepared_statement.append_sql(" AS " <> name)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ From                                                                      │
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
  from from: From,
) -> PreparedStatement {
  case from {
    NoFrom -> prepared_statement
    FromTable(name:) ->
      prepared_statement
      |> prepared_statement.append_sql(" FROM " <> name)
    FromSubQuery(query, alias) ->
      prepared_statement
      |> prepared_statement.append_sql(" FROM (")
      |> apply(query:)
      |> prepared_statement.append_sql(") AS " <> alias)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Where                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Describes the `WHERE` clause of SQL queries.
///
/// NOTICE: 🪶SQLite does _not_ support:
///
/// - `ANY` (`WhereAny*`),
/// - `ALL` (`WhereAny*`) and,
/// - `SIMILAR TO` (`WhereSimilarTo`)
///
pub type Where {
  NoWhere
  NotWhere(condition: Where)
  AndWhere(conditions: List(Where))
  OrWhere(conditions: List(Where))
  XorWhere(conditions: List(Where))
  XorParityWhere(conditions: List(Where))
  WhereIsBool(value: WhereValue, expected: Bool)
  WhereIsNotBool(value: WhereValue, expected: Bool)
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
  WhereFragment(value: Fragment)
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
  WhereColumnValue(name: String)
  WhereParamValue(value: Param)
  WhereFragmentValue(value: Fragment)
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
  where where: Where,
) -> PreparedStatement {
  case where {
    NoWhere -> prepared_statement
    _ ->
      prepared_statement
      |> prepared_statement.append_sql(" WHERE ")
      |> where_apply(where:)
  }
}

fn having_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where where: Where,
) -> PreparedStatement {
  case where {
    NoWhere -> prepared_statement
    _ ->
      prepared_statement
      |> prepared_statement.append_sql(" HAVING ")
      |> where_apply(where:)
  }
}

fn where_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where where: Where,
) -> PreparedStatement {
  case where {
    NoWhere -> prepared_statement
    AndWhere(conditions:) ->
      prepared_statement
      |> where_logical_operator_apply(
        operator: "AND",
        where: conditions,
        wrap_in_parentheses: False,
      )
    OrWhere(conditions:) ->
      prepared_statement
      |> where_logical_operator_apply(
        operator: "OR",
        where: conditions,
        wrap_in_parentheses: True,
      )
    XorWhere(conditions:) ->
      prepared_statement
      |> where_xor_apply(where: conditions)
    XorParityWhere(conditions:) ->
      prepared_statement
      |> where_xor_parity_apply(where: conditions)
    NotWhere(condition:) ->
      prepared_statement
      |> prepared_statement.append_sql("NOT(")
      |> where_apply(where: condition)
      |> prepared_statement.append_sql(")")
    WhereIsBool(value, True) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS TRUE")
    WhereIsBool(value, False) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS FALSE")
    WhereIsNotBool(value, True) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS NOT TRUE")
    WhereIsNotBool(value, False) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS NOT FALSE")
    WhereIsNull(value) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS NULL")
    WhereIsNotNull(value) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "IS NOT NULL")
    WhereComparison(value_a, Equal, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: "=", value_b:)
    WhereComparison(value_a, Greater, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: ">", value_b:)
    WhereComparison(value_a, GreaterOrEqual, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: ">=", value_b:)
    WhereComparison(value_a, Lower, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: "<", value_b:)
    WhereComparison(value_a, LowerOrEqual, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: "<=", value_b:)
    WhereComparison(value_a, Unequal, value_b) ->
      prepared_statement
      |> where_comparison_apply(value_a:, operator: "<>", value_b:)
    WhereAnyOfSubQuery(value, Equal, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "= ANY")
      |> where_sub_query_apply(query:)
    WhereAnyOfSubQuery(value, Greater, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "> ANY")
      |> where_sub_query_apply(query:)
    WhereAnyOfSubQuery(value, GreaterOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: ">= ANY")
      |> where_sub_query_apply(query:)
    WhereAnyOfSubQuery(value, Lower, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "< ANY")
      |> where_sub_query_apply(query:)
    WhereAnyOfSubQuery(value, LowerOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "<= ANY")
      |> where_sub_query_apply(query:)
    WhereAnyOfSubQuery(value, Unequal, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "<> ANY")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, Equal, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "= ALL")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, Greater, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "> ALL")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, GreaterOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: ">= ALL")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, Lower, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "< ALL")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, LowerOrEqual, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "<= ALL")
      |> where_sub_query_apply(query:)
    WhereAllOfSubQuery(value, Unequal, query) ->
      prepared_statement
      |> where_literal_apply(value:, literal: "<> ALL")
      |> where_sub_query_apply(query:)
    WhereBetween(value_a, value_b, value_c) ->
      prepared_statement
      |> where_between_apply(value_a:, value_b:, value_c:)
    WhereIn(value, values) ->
      prepared_statement
      |> where_value_in_values_apply(value:, values:)
    WhereExistsInSubQuery(query:) ->
      prepared_statement
      |> prepared_statement.append_sql(" EXISTS ")
      |> where_sub_query_apply(query:)
    WhereLike(value, param) ->
      prepared_statement
      |> where_comparison_apply(
        value_a: value,
        operator: "LIKE",
        value_b: param |> StringParam |> WhereParamValue,
      )
    WhereILike(value:, pattern: param) ->
      prepared_statement
      |> where_comparison_apply(
        value_a: value,
        operator: "ILIKE",
        value_b: param |> StringParam |> WhereParamValue,
      )
    WhereSimilarTo(value:, pattern: param, escape_char:) ->
      prepared_statement
      |> where_comparison_apply(
        value_a: value,
        operator: "SIMILAR TO",
        value_b: param |> StringParam |> WhereParamValue,
      )
      |> prepared_statement.append_sql(" ESCAPE '" <> escape_char <> "'")
    WhereFragment(value:) ->
      prepared_statement
      |> fragment_apply(fragment: value)
  }
}

fn where_literal_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value value: WhereValue,
  literal literal: String,
) -> PreparedStatement {
  case value {
    WhereColumnValue(name:) ->
      prepared_statement
      |> prepared_statement.append_sql(name <> " " <> literal)
    WhereParamValue(value:) ->
      prepared_statement |> prepared_statement.append_param(value)
    WhereFragmentValue(value:) ->
      prepared_statement
      |> fragment_apply(fragment: value)
      |> prepared_statement.append_sql(" " <> literal)
    WhereSubQueryValue(query:) ->
      prepared_statement
      |> where_sub_query_apply(query:)
      |> prepared_statement.append_sql(" " <> literal)
  }
}

fn where_comparison_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value_a value_a: WhereValue,
  operator operator: String,
  value_b value_b: WhereValue,
) -> PreparedStatement {
  case value_a, value_b {
    WhereColumnValue(column_a), WhereColumnValue(column_b) ->
      prepared_statement
      |> where_sql_apply(column_a <> " " <> operator <> " " <> column_b)
    WhereColumnValue(column), WhereParamValue(param) ->
      prepared_statement
      |> where_sql_apply(column <> " " <> operator <> " ")
      |> where_param_apply(param:)
    WhereParamValue(param), WhereColumnValue(column) ->
      prepared_statement
      |> where_param_apply(param:)
      |> where_sql_apply(" " <> operator <> " " <> column)
    WhereParamValue(param_a), WhereParamValue(param_b) ->
      prepared_statement
      |> where_param_apply(param: param_a)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_param_apply(param: param_b)
    WhereFragmentValue(value), WhereColumnValue(column) ->
      prepared_statement
      |> fragment_apply(fragment: value)
      |> where_sql_apply(" " <> operator <> " " <> column)
    WhereColumnValue(column), WhereFragmentValue(value) ->
      prepared_statement
      |> where_sql_apply(column <> " " <> operator <> " ")
      |> fragment_apply(fragment: value)
    WhereFragmentValue(value), WhereParamValue(param) ->
      prepared_statement
      |> fragment_apply(fragment: value)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_param_apply(param:)
    WhereParamValue(param), WhereFragmentValue(value) ->
      prepared_statement
      |> where_param_apply(param:)
      |> where_sql_apply(" " <> operator <> " ")
      |> fragment_apply(fragment: value)
    WhereFragmentValue(value_a), WhereFragmentValue(value_b) ->
      prepared_statement
      |> fragment_apply(fragment: value_a)
      |> where_sql_apply(" " <> operator <> " ")
      |> fragment_apply(fragment: value_b)
    WhereSubQueryValue(query_a), WhereSubQueryValue(query_b) ->
      prepared_statement
      |> where_sub_query_apply(query: query_a)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_sub_query_apply(query: query_b)
    WhereColumnValue(column), WhereSubQueryValue(query) ->
      prepared_statement
      |> where_sql_apply(column <> " " <> operator <> " ")
      |> where_sub_query_apply(query:)
    WhereSubQueryValue(query), WhereColumnValue(column) ->
      prepared_statement
      |> where_sub_query_apply(query:)
      |> where_sql_apply(" " <> operator <> " " <> column)
    WhereParamValue(param), WhereSubQueryValue(query) ->
      prepared_statement
      |> where_param_apply(param:)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_sub_query_apply(query:)
    WhereSubQueryValue(query), WhereParamValue(param) ->
      prepared_statement
      |> where_sub_query_apply(query:)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_param_apply(param:)
    WhereFragmentValue(value), WhereSubQueryValue(query) ->
      prepared_statement
      |> fragment_apply(fragment: value)
      |> where_sql_apply(" " <> operator <> " ")
      |> where_sub_query_apply(query:)
    WhereSubQueryValue(query), WhereFragmentValue(value) ->
      prepared_statement
      |> where_sub_query_apply(query:)
      |> where_sql_apply(" " <> operator <> " ")
      |> fragment_apply(fragment: value)
  }
}

fn where_sql_apply(
  prepared_statement prepared_statement: PreparedStatement,
  sql sql: String,
) -> PreparedStatement {
  prepared_statement |> prepared_statement.append_sql(sql:)
}

fn where_param_apply(
  prepared_statement prepared_statement: PreparedStatement,
  param param: Param,
) -> PreparedStatement {
  prepared_statement |> prepared_statement.append_param(param:)
}

fn where_sub_query_apply(
  prepared_statement prepared_statement: PreparedStatement,
  query query: ReadQuery,
) -> PreparedStatement {
  prepared_statement
  |> prepared_statement.append_sql("(")
  |> apply(query:)
  |> prepared_statement.append_sql(")")
}

fn where_logical_operator_apply(
  prepared_statement prepared_statement: PreparedStatement,
  operator operator: String,
  where wheres: List(Where),
  wrap_in_parentheses wrap_in_parentheses: Bool,
) -> PreparedStatement {
  let prepared_statement = case wrap_in_parentheses {
    True -> prepared_statement |> prepared_statement.append_sql("(")
    False -> prepared_statement
  }

  let prepared_statement =
    wheres
    |> list.fold(
      from: prepared_statement,
      with: fn(new_prepared_statement: PreparedStatement, where: Where) -> PreparedStatement {
        case new_prepared_statement == prepared_statement {
          True ->
            new_prepared_statement
            |> where_apply(where:)
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql(" " <> operator <> " ")
            |> where_apply(where:)
        }
      },
    )

  let prepared_statement = case wrap_in_parentheses {
    True -> prepared_statement |> prepared_statement.append_sql(")")
    False -> prepared_statement
  }

  prepared_statement
}

fn where_xor_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where wheres: List(Where),
) -> PreparedStatement {
  let xor_indexes =
    int.range(
      from: 0,
      to: wheres |> list.length,
      with: [],
      run: fn(accumulator, i) { [i, ..accumulator] },
    )
    |> list.reverse

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("(")

  let prepared_statement =
    xor_indexes
    |> list.fold(
      from: prepared_statement,
      with: fn(new_prepared_statement: PreparedStatement, xor_index: Int) -> PreparedStatement {
        let new_prepared_statement = case
          new_prepared_statement == prepared_statement
        {
          True -> new_prepared_statement
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql(") OR (")
        }

        let #(new_prepared_statement, _last_where_index) =
          wheres
          |> list.fold(
            from: #(new_prepared_statement, 0),
            with: fn(accumulator: #(PreparedStatement, Int), where: Where) -> #(
              PreparedStatement,
              Int,
            ) {
              let #(new_prepared_statement_per_xor, where_index) = accumulator
              let new_prepared_statement_per_xor = case
                where_index == xor_index,
                where_index
              {
                True, 0 ->
                  new_prepared_statement_per_xor
                  |> where_apply(where:)
                True, _gt_0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql(" AND (")
                  |> where_apply(where:)
                  |> prepared_statement.append_sql(")")
                False, 0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql("NOT(")
                  |> where_apply(where:)
                  |> prepared_statement.append_sql(")")
                False, _gt_0 ->
                  new_prepared_statement_per_xor
                  |> prepared_statement.append_sql(" AND NOT(")
                  |> where_apply(where:)
                  |> prepared_statement.append_sql(")")
              }
              #(new_prepared_statement_per_xor, where_index + 1)
            },
          )

        new_prepared_statement
      },
    )

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(")")

  prepared_statement
}

fn where_xor_parity_apply(
  prepared_statement prepared_statement: PreparedStatement,
  where wheres: List(Where),
) -> PreparedStatement {
  case prepared_statement |> prepared_statement.get_dialect {
    Postgres -> where_postgres_xor_parity_apply(prepared_statement:, wheres:)
    Sqlite -> where_sqlite_xor_parity_apply(prepared_statement:, wheres:)
    Maria | Mysql ->
      where_maria_mysql_xor_parity_apply(prepared_statement:, wheres:)
  }
}

// Sums each predicate cast to int then checks odd parity.
// `(cond)::int` yields 1, 0, or NULL, so a single NULL operand
// propagates NULL through `+` and `%`, matching MariaDB/MySQL XOR
// semantics where `NULL XOR anything = NULL`.
fn where_postgres_xor_parity_apply(
  prepared_statement prepared_statement: PreparedStatement,
  wheres wheres: List(Where),
) -> PreparedStatement {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("((")

  let prepared_statement =
    wheres
    |> list.fold(
      from: prepared_statement,
      with: fn(new_prepared_statement: PreparedStatement, where: Where) -> PreparedStatement {
        case new_prepared_statement == prepared_statement {
          True ->
            new_prepared_statement
            |> prepared_statement.append_sql("(")
            |> where_apply(where:)
            |> prepared_statement.append_sql(")::int")
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql(" + (")
            |> where_apply(where:)
            |> prepared_statement.append_sql(")::int")
        }
      },
    )

  prepared_statement |> prepared_statement.append_sql(") % 2) = 1")
}

// Sums each predicate result directly then checks odd parity.
// SQLite uses dynamic typing: comparisons already return 1, 0, or NULL,
// so bare `(cond)` participates in arithmetic without a cast. A NULL
// operand propagates NULL through `+` and `%`, matching MariaDB/MySQL
// XOR semantics where `NULL XOR anything = NULL`.
fn where_sqlite_xor_parity_apply(
  prepared_statement prepared_statement: PreparedStatement,
  wheres wheres: List(Where),
) -> PreparedStatement {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("((")

  let prepared_statement =
    wheres
    |> list.fold(
      from: prepared_statement,
      with: fn(new_prepared_statement: PreparedStatement, where: Where) -> PreparedStatement {
        case new_prepared_statement == prepared_statement {
          True ->
            new_prepared_statement
            |> prepared_statement.append_sql("(")
            |> where_apply(where:)
            |> prepared_statement.append_sql(")")
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql(" + (")
            |> where_apply(where:)
            |> prepared_statement.append_sql(")")
        }
      },
    )

  prepared_statement |> prepared_statement.append_sql(") % 2) = 1")
}

fn where_maria_mysql_xor_parity_apply(
  prepared_statement prepared_statement: PreparedStatement,
  wheres wheres: List(Where),
) -> PreparedStatement {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql("(")

  wheres
  |> list.fold(
    from: prepared_statement,
    with: fn(new_prepared_statement: PreparedStatement, where: Where) -> PreparedStatement {
      case new_prepared_statement == prepared_statement {
        True -> new_prepared_statement |> where_apply(where:)
        False ->
          new_prepared_statement
          |> prepared_statement.append_sql(" XOR ")
          |> where_apply(where:)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_value_in_values_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value value: WhereValue,
  values values: List(WhereValue),
) -> PreparedStatement {
  let prepared_statement =
    case value {
      WhereColumnValue(name:) ->
        prepared_statement |> prepared_statement.append_sql(name)
      WhereParamValue(value:) ->
        prepared_statement |> prepared_statement.append_param(value)
      WhereFragmentValue(value:) ->
        prepared_statement |> fragment_apply(fragment: value)
      WhereSubQueryValue(query:) ->
        prepared_statement |> where_sub_query_apply(query:)
    }
    |> prepared_statement.append_sql(" IN (")

  values
  |> list.fold(
    from: prepared_statement,
    with: fn(new_prepared_statement: PreparedStatement, value: WhereValue) -> PreparedStatement {
      case value {
        WhereColumnValue(name:) ->
          case new_prepared_statement == prepared_statement {
            True ->
              new_prepared_statement
              |> prepared_statement.append_sql(name)
            False ->
              new_prepared_statement
              |> prepared_statement.append_sql(", " <> name)
          }
        WhereParamValue(value:) ->
          case new_prepared_statement == prepared_statement {
            True -> ""
            False -> ", "
          }
          |> prepared_statement.append_sql(
            prepared_statement: new_prepared_statement,
            sql: _,
          )
          |> prepared_statement.append_param(param: value)
        WhereFragmentValue(value:) ->
          case new_prepared_statement == prepared_statement {
            True -> new_prepared_statement
            False ->
              new_prepared_statement |> prepared_statement.append_sql(", ")
          }
          |> fragment_apply(fragment: value)
        WhereSubQueryValue(query:) ->
          case new_prepared_statement == prepared_statement {
            True -> new_prepared_statement
            False ->
              new_prepared_statement |> prepared_statement.append_sql(", ")
          }
          |> where_sub_query_apply(query:)
      }
    },
  )
  |> prepared_statement.append_sql(")")
}

fn where_between_apply(
  prepared_statement prepared_statement: PreparedStatement,
  value_a value_a: WhereValue,
  value_b value_b: WhereValue,
  value_c value_c: WhereValue,
) -> PreparedStatement {
  let prepared_statement = case value_a {
    WhereColumnValue(name:) ->
      prepared_statement |> prepared_statement.append_sql(name)
    WhereParamValue(value:) ->
      prepared_statement |> prepared_statement.append_param(value)
    WhereFragmentValue(value:) ->
      prepared_statement |> fragment_apply(fragment: value)
    WhereSubQueryValue(query:) ->
      prepared_statement |> where_sub_query_apply(query:)
  }

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" BETWEEN ")

  let prepared_statement = case value_b {
    WhereColumnValue(name:) ->
      prepared_statement |> prepared_statement.append_sql(name)
    WhereParamValue(value:) ->
      prepared_statement |> prepared_statement.append_param(value)
    WhereFragmentValue(value:) ->
      prepared_statement |> fragment_apply(fragment: value)
    WhereSubQueryValue(query:) ->
      prepared_statement |> where_sub_query_apply(query:)
  }

  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" AND ")

  let prepared_statement = case value_c {
    WhereColumnValue(name:) ->
      prepared_statement |> prepared_statement.append_sql(name)
    WhereParamValue(value:) ->
      prepared_statement |> prepared_statement.append_param(value)
    WhereFragmentValue(value:) ->
      prepared_statement |> fragment_apply(fragment: value)
    WhereSubQueryValue(query:) ->
      prepared_statement |> where_sub_query_apply(query:)
  }

  prepared_statement
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Group By                                                                  │
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
  group_by group_by: GroupBy,
) -> PreparedStatement {
  case group_by {
    NoGroupBy -> prepared_statement
    GroupBy(columns:) ->
      prepared_statement
      |> prepared_statement.append_sql(" GROUP BY ")
      |> group_by_apply(group_bys: columns)
  }
}

fn group_by_apply(
  prepared_statement prepared_statement: PreparedStatement,
  group_bys group_bys: List(String),
) -> PreparedStatement {
  case group_bys {
    [] -> prepared_statement
    _ ->
      group_bys
      |> list.fold(
        from: prepared_statement,
        with: fn(new_prepared_statement: PreparedStatement, sql: String) -> PreparedStatement {
          case new_prepared_statement == prepared_statement {
            True ->
              new_prepared_statement |> prepared_statement.append_sql(sql:)
            False ->
              new_prepared_statement
              |> prepared_statement.append_sql(", " <> sql)
          }
        },
      )
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Joins                                                                     │
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
  Joins(items: List(Join))
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
  joins joins: Joins,
) -> PreparedStatement {
  case joins {
    Joins(items:) -> {
      items
      |> list.fold(
        from: prepared_statement,
        with: fn(new_prepared_statement: PreparedStatement, join: Join) -> PreparedStatement {
          let join_command_apply = fn(
            new_prepared_statement: PreparedStatement,
            sql_command: String,
          ) -> PreparedStatement {
            new_prepared_statement
            |> prepared_statement.append_sql(" " <> sql_command <> " ")
            |> join_apply(join)
          }

          let on_apply = fn(
            new_prepared_statement: PreparedStatement,
            on: Where,
          ) -> PreparedStatement {
            new_prepared_statement
            |> prepared_statement.append_sql(" ON ")
            |> where_apply(where: on)
          }

          case join {
            InnerJoin(_, alias: _, on:) ->
              new_prepared_statement
              |> join_command_apply("INNER JOIN")
              |> on_apply(on)
            InnerJoinLateralOnTrue(_, alias: _) ->
              new_prepared_statement
              |> join_command_apply("INNER JOIN LATERAL")
              |> prepared_statement.append_sql(" ON TRUE")
            LeftJoin(_, alias: _, on:) ->
              new_prepared_statement
              |> join_command_apply("LEFT OUTER JOIN")
              |> on_apply(on)
            LeftJoinLateralOnTrue(_, alias: _) ->
              new_prepared_statement
              |> join_command_apply("LEFT JOIN LATERAL")
              |> prepared_statement.append_sql(" ON TRUE")
            RightJoin(_, alias: _, on:) ->
              new_prepared_statement
              |> join_command_apply("RIGHT OUTER JOIN")
              |> on_apply(on)
            FullJoin(_, alias: _, on:) ->
              new_prepared_statement
              |> join_command_apply("FULL OUTER JOIN")
              |> on_apply(on)
            CrossJoin(_, alias: _) ->
              new_prepared_statement |> join_command_apply("CROSS JOIN")
            CrossJoinLateral(_, alias: _) ->
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
  join join: Join,
) -> PreparedStatement {
  case join.with {
    JoinTable(table:) ->
      prepared_statement
      |> prepared_statement.append_sql(table <> " AS " <> join.alias)
    JoinSubQuery(query:) ->
      prepared_statement
      |> prepared_statement.append_sql("(")
      |> apply(query:)
      |> prepared_statement.append_sql(") AS " <> join.alias)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Order By                                                                  │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare an order by clause.
///
pub type OrderBy {
  NoOrderBy
  OrderBy(order_bys: List(OrderByValue))
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
/// - `AscNullsFirst` - Ascending order with nulls first, NOT supported by
///   🦭MariaDB or 🐬MySQL
/// - `AscNullsLast` - Ascending order with nulls last, NOT supported by
///   🦭MariaDB or 🐬MySQL
/// - `Desc` - Descending order
/// - `DescNullsFirst` - Descending order with nulls first, NOT supported by
///    🦭MariaDB or 🐬MySQL
/// - `DescNullsLast` - Descending order with nulls last, NOT supported by
///    🦭MariaDB or 🐬MySQL
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
  existing_order_by existing_order_by: OrderBy,
  order_by new_order_by: OrderBy,
) -> OrderBy {
  case existing_order_by, new_order_by {
    NoOrderBy, _ -> new_order_by
    _, NoOrderBy -> existing_order_by
    OrderBy(existing_items), OrderBy(new_items) -> {
      let combined = list.append(existing_items, new_items)
      OrderBy(combined)
    }
  }
}

fn order_by_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  order_by order_by: OrderBy,
) -> PreparedStatement {
  case order_by {
    NoOrderBy -> prepared_statement
    OrderBy(order_bys:) -> {
      case order_bys {
        [] -> prepared_statement
        vs -> {
          let prepared_statement =
            prepared_statement
            |> prepared_statement.append_sql(" ORDER BY ")

          vs
          |> list.fold(
            from: prepared_statement,
            with: fn(
              new_prepared_statement: PreparedStatement,
              value: OrderByValue,
            ) -> PreparedStatement {
              case new_prepared_statement == prepared_statement {
                True -> new_prepared_statement |> order_by_value_apply(value:)
                False ->
                  new_prepared_statement
                  |> prepared_statement.append_sql(", ")
                  |> order_by_value_apply(value:)
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
  value value: OrderByValue,
) -> PreparedStatement {
  case value {
    OrderByColumn(column:, direction:) ->
      prepared_statement
      |> prepared_statement.append_sql(column)
      |> prepared_statement.append_sql(
        sql: " " <> direction |> order_by_direction_to_sql,
      )
    OrderByFragment(fragment:, direction:) ->
      prepared_statement
      |> fragment_apply(fragment: fragment)
      |> prepared_statement.append_sql(
        sql: " " <> direction |> order_by_direction_to_sql,
      )
  }
}

/// NOTICE: 🦭MariaDB and 🐬MySQL do not support `NULLS FIRST` or `NULLS LAST`.
/// Instead, `NULL`s are considered to have the lowest value, thus ordering in
/// `DESC` order will see the `NULL`s appearing last. To force `NULL`s to be
/// regarded as highest values, see
/// <https://mariadb.com/kb/en/null-values/#ordering>.
///
fn order_by_direction_to_sql(
  order_by_direction order_by_direction: OrderByDirection,
) -> String {
  case order_by_direction {
    Asc -> "ASC"
    AscNullsFirst -> "ASC NULLS FIRST"
    AscNullsLast -> "ASC NULLS LAST"
    Desc -> "DESC"
    DescNullsFirst -> "DESC NULLS FIRST"
    DescNullsLast -> "DESC NULLS LAST"
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Limit                                                                     │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare a limit clause.
///
pub type Limit {
  NoLimit
  Limit(limit: Int)
}

/// Create a new limit clause.
///
pub fn limit_new(limit limit: Int) -> Limit {
  case limit > 0 {
    False -> NoLimit
    True -> Limit(limit:)
  }
}

fn limit_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  limit limit: Limit,
) -> PreparedStatement {
  case limit {
    NoLimit -> ""
    Limit(limit:) -> " LIMIT " <> limit |> int.to_string
  }
  |> prepared_statement.append_sql(prepared_statement:)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Offset                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Declare an offset clause.
///
pub type Offset {
  NoOffset
  Offset(offset: Int)
}

/// Create a new offset clause.
///
pub fn offset_new(offset offset: Int) -> Offset {
  case offset > 0 {
    False -> NoOffset
    True -> Offset(offset:)
  }
}

fn offset_clause_apply(
  prepared_statement prepared_statement: PreparedStatement,
  offset offset: Offset,
) -> PreparedStatement {
  case offset {
    NoOffset -> ""
    Offset(offset:) -> " OFFSET " <> offset |> int.to_string
  }
  |> prepared_statement.append_sql(prepared_statement:)
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Epilog                                                                    │
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
  epilog epilog: Epilog,
) -> PreparedStatement {
  case epilog {
    NoEpilog -> prepared_statement
    Epilog(string:) ->
      prepared_statement |> prepared_statement.append_sql(string)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Comment                                                                   │
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
  comment comment: Comment,
) -> PreparedStatement {
  case comment {
    NoComment -> prepared_statement
    Comment(string:) ->
      case
        string |> string.contains(contain: "\n")
        || string |> string.contains(contain: "\r")
      {
        True ->
          prepared_statement
          |> prepared_statement.append_sql(
            sql: " /* "
            <> string
            |> string.trim
            |> string.replace(each: "*/", with: "* /")
            |> string.replace(each: "/*", with: "/ *")
            <> " */",
          )
        False ->
          prepared_statement
          |> prepared_statement.append_sql(" -- " <> string |> string.trim)
      }
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Fragment                                                                  │
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
  FragmentLiteral(value: String)
  FragmentPrepared(value: String, params: List(Param))
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
  string_fragment string_fragment: String,
) -> List(String) {
  string_fragment
  |> string.to_graphemes
  |> list.fold(
    from: [],
    with: fn(accumulator: List(String), grapheme: String) -> List(String) {
      case grapheme == fragment_placeholder_grapheme, accumulator {
        // If encountering a placeholder, we want to add it as a single item.
        True, _acc -> [fragment_placeholder_grapheme, ..accumulator]
        // If Encountering anything else but there isn't anything yet, we want to
        // add it as a single item.
        False, [] -> [grapheme]
        // If the previous item matches a placeholder, we don't want to append
        // to it, because we want placeholders to exist as separate single items.
        False, [x, ..] if x == fragment_placeholder_grapheme -> [
          grapheme,
          ..accumulator
        ]
        // In any other case we can just append to the previous item.
        False, [x, ..xs] -> [x <> grapheme, ..xs]
      }
    },
  )
  |> list.reverse
}

pub fn fragment_apply(
  prepared_statement prepared_statement: PreparedStatement,
  fragment fragment: Fragment,
) -> PreparedStatement {
  case fragment {
    FragmentLiteral(value:) ->
      prepared_statement |> prepared_statement.append_sql(value)
    FragmentPrepared(value:, params: []) ->
      // This is likely a user error and they meant `FragmentLiteral`
      // if the user did not give any params.
      prepared_statement |> prepared_statement.append_sql(value)
    FragmentPrepared(value:, params:) -> {
      let fragments = value |> fragment_prepared_split_string
      let fragment_placeholder_count = fragments |> fragment_count_placeholders
      let params_count = params |> list.length

      // Fill up or reduce params to match the given number of placeholders
      // in the fragment.
      //
      // Param count not equal fragment placeholder count is likely a user
      // error that cannot be caught by the type system.
      //
      // For the user `fragment.prepared()` should be used with caution and will
      // warn about the mismatch at runtime.
      let params = case
        fragment_placeholder_count |> int.compare(with: params_count)
      {
        // Expected match: No user error
        order.Eq -> params
        // User error: Too many params or not enough placeholders
        order.Lt ->
          // If there are more params than placeholders, we take the first `n`
          // params where `n` is the number of placeholders, and discard the
          // rest.
          // TODO: consider logger.warning at runtime.
          params |> list.take(up_to: fragment_placeholder_count)
        // User error: Not enough params or too many placeholders
        order.Gt ->
          case params |> list.last {
            Ok(last_item) -> {
              // If there are more placeholders than params, we repeat the last
              // param until the number of placeholders is reached.
              let missing_params_count =
                fragment_placeholder_count - params_count
              let repeated_last_item =
                last_item |> list.repeat(times: missing_params_count)
              // TODO: consider logger.warning at runtime.
              params |> list.append(repeated_last_item)
            }
            // Unreachable, because of the match above:
            // `FragmentPrepared(value:, params: []) ->`
            Error(Nil) -> params
          }
      }

      case fragments {
        // NOOP on no fragments
        [] -> prepared_statement
        // Some fragments
        fragments -> {
          let #(new_prepared_statement, _param_rest) =
            fragments
            |> list.fold(
              from: #(prepared_statement, params),
              with: fn(
                accumulator: #(PreparedStatement, List(Param)),
                fragment: String,
              ) -> #(PreparedStatement, List(Param)) {
                let #(new_prepared_statement, params) = accumulator
                case fragment == fragment_placeholder_grapheme, params {
                  False, _ -> #(
                    new_prepared_statement
                      |> prepared_statement.append_sql(fragment),
                    params,
                  )
                  True, [param, ..rest_params] -> #(
                    new_prepared_statement
                      |> prepared_statement.append_param(param:),
                    rest_params,
                  )
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
  |> list.fold(from: 0, with: fn(count: Int, string_fragment: String) -> Int {
    case string_fragment == fragment_placeholder_grapheme {
      True -> count + 1
      False -> count
    }
  })
}
