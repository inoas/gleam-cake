//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

// TODO v3 Add to query validator?

import cake/fragment.{type Fragment}
import cake/internal/dialect.{type Dialect}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{
  type Comment, type Epilog, type From, type Joins, type ReadQuery, type Where,
  FromSubQuery, FromTable, NoFrom,
}
import cake/param.{type Param}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Write Query                                                               │
// └───────────────────────────────────────────────────────────────────────────┘

/// Write queries encapsulate the different types of write operations
/// in SQL Databases, such as `INSERT`, `UPDATE` and `DELETE`.
///
/// While read queries never use write queries, write queries can use read
/// queries, as they can use subqueries to define the data to be written or they
/// are being utilized for atomic updates or conflict resolution.
///
pub type WriteQuery(a) {
  InsertQuery(Insert(a))
  UpdateQuery(Update(a))
  DeleteQuery(Delete(a))
}

/// Converts a `WriteQuery` into a `PreparedStatement`.
///
pub fn to_prepared_statement(
  query query: WriteQuery(a),
  placeholder_base placeholder_base: String,
  dialect dialect: Dialect,
) -> PreparedStatement {
  placeholder_base
  |> prepared_statement.new(dialect)
  |> apply(query)
}

fn apply(
  prepared_statement prepared_statement: PreparedStatement,
  query query: WriteQuery(a),
) -> PreparedStatement {
  case query {
    InsertQuery(insert) -> prepared_statement |> insert_apply(insert)
    UpdateQuery(update) -> prepared_statement |> update_apply(update)
    DeleteQuery(delete) -> prepared_statement |> delete_apply(delete)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Returning                                                                 │
// └───────────────────────────────────────────────────────────────────────────┘

/// `Returning` is used to define the columns to be returned after a write query
/// has been executed.
///
pub type Returning {
  NoReturning
  Returning(columns: List(String))
}

fn returning_apply(
  prepared_statement prepared_statement: PreparedStatement,
  returning returning: Returning,
) -> PreparedStatement {
  case returning {
    NoReturning -> prepared_statement
    Returning(columns:) ->
      prepared_statement
      |> prepared_statement.append_sql(" RETURNING ")
      |> prepared_statement.append_sql(columns |> string.join(", "))
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Insert                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Defines an `INSERT` query.
///
pub type Insert(a) {
  Insert(
    // with (_recursive?): ?, // v2
    table: InsertIntoTable,
    columns: InsertColumns,
    modifier: InsertModifier,
    source: InsertSource(a),
    on_conflict: InsertConflictStrategy(a),
    returning: Returning,
    epilog: Epilog,
    comment: Comment,
  )
}

/// The `InsertIntoTable` type is used to define the table to insert data into.
///
pub type InsertIntoTable {
  NoInsertIntoTable
  InsertIntoTable(name: String)
}

/// The `InsertColumns` type is used to define the columns to insert data into.
///
pub type InsertColumns {
  NoInsertColumns
  InsertColumns(columns: List(String))
}

/// The `InsertModifier` type is used to define the modifier to be used when
/// inserting data into a table.
///
pub type InsertModifier {
  NoInsertModifier
  InsertModifier(modifier: String)
}

/// The `InsertSource` type is used to define the source of the data to be
/// inserted into a table. It can be:
///
/// - `NoInsertSource` when no source is provided.
/// - `InsertSourceDefault` when the default values are used.
/// - `InsertSourceRecords` when a list of records is provided.
/// - `InsertSourceRows` when a list of rows is provided.
/// - `InsertSourceQuery` when a query is provided.
///
pub type InsertSource(a) {
  NoInsertSource
  InsertSourceDefault
  InsertSourceRecords(records: List(a), encoder: fn(a) -> InsertRow)
  InsertSourceRows(rows: List(InsertRow))
  InsertSourceQuery(query: ReadQuery)
}

/// The `InsertRow` type is used to define a row to be inserted into a table.
///
pub type InsertRow {
  InsertRow(row: List(InsertValue))
}

/// The `InsertValue` type is used to define the values to be inserted into
/// a table. It can be a parameter or a default value.
///
pub type InsertValue {
  InsertParam(param: Param)
  InsertDefault
  /// A fragment value, e.g. `fragment.prepared("$::uuid", [fragment.string(id)])`.
  /// Allows type casts and expressions in INSERT VALUES which for instance
  /// 🐘Postgres may require.
  InsertFragment(fragment: Fragment)
}

/// The `InsertConflictStrategy` defines how to handle conflicts when inserting
/// data into a table.
///
/// - `InsertConflictError` is the default behaviour, which will raise an error.
/// - `InsertConflictUpdate` is also known as `INSERT OR UPDATE` aka `UPSERT`.
/// - `InsertConflictIgnore` is also known as `INSERT IGNORE`.
///
pub type InsertConflictStrategy(a) {
  InsertConflictError
  InsertConflictIgnore(target: InsertConflictTarget, where: Where)
  InsertConflictUpdate(
    target: InsertConflictTarget,
    where: Where,
    update: Update(a),
  )
}

/// The `InsertConflictTarget` type is used to define the target of the conflict
/// resolution.
///
pub type InsertConflictTarget {
  InsertConflictTarget(columns: List(String))
  InsertConflictTargetConstraint(constraint: String)
}

fn insert_apply(
  prepared_statement prepared_statement: PreparedStatement,
  insert insert: Insert(a),
) {
  case
    prepared_statement |> prepared_statement.get_dialect,
    insert.on_conflict
  {
    // 🦭MariaDB and 🐬MySQL do not support `ON CONFLICT`.
    // `InsertConflictIgnore` is translated to `INSERT IGNORE INTO`, which
    // silently discards all key-constraint violations on any column.
    //
    // ⚠️  `INSERT IGNORE` is broader than `ON CONFLICT DO NOTHING`:
    //   - it applies to every unique/primary-key constraint, not just the
    //     specified target columns.
    //   - it also suppresses other warnings such as data-truncation errors.
    //   - the index predicate (`WHERE`) has no equivalent and is dropped.
    dialect.Maria, InsertConflictIgnore(..)
    | dialect.Mysql, InsertConflictIgnore(..)
    ->
      prepared_statement
      |> insert_conflict_ignore_maria_mysql_apply(insert)
      |> returning_apply(insert.returning)
      |> read_query.comment_apply(insert.comment)
      |> read_query.epilog_apply(insert.epilog)
    _, _ ->
      prepared_statement
      |> insert_into_table_apply(insert.table)
      |> insert_columns_apply(insert.columns)
      |> insert_modifier_apply(insert.modifier)
      |> insert_source_apply(insert.source)
      |> insert_on_conflict_apply(insert.on_conflict)
      |> returning_apply(insert.returning)
      |> read_query.comment_apply(insert.comment)
      |> read_query.epilog_apply(insert.epilog)
  }
}

fn insert_into_table_apply(
  prepared_statement prepared_statement: PreparedStatement,
  table_name table_name: InsertIntoTable,
) -> PreparedStatement {
  case table_name {
    NoInsertIntoTable ->
      prepared_statement |> prepared_statement.append_sql("INSERT INTO")
    InsertIntoTable(name: table_name) ->
      prepared_statement
      |> prepared_statement.append_sql("INSERT INTO " <> table_name)
  }
}

fn insert_ignore_into_table_apply(
  prepared_statement prepared_statement: PreparedStatement,
  table_name table_name: InsertIntoTable,
) -> PreparedStatement {
  case table_name {
    NoInsertIntoTable ->
      prepared_statement |> prepared_statement.append_sql("INSERT IGNORE INTO")
    InsertIntoTable(name: table_name) ->
      prepared_statement
      |> prepared_statement.append_sql("INSERT IGNORE INTO " <> table_name)
  }
}

fn insert_columns_apply(
  prepared_statement prepared_statement: PreparedStatement,
  columns columns: InsertColumns,
) -> PreparedStatement {
  case columns {
    NoInsertColumns -> prepared_statement
    InsertColumns(columns:) ->
      prepared_statement
      |> prepared_statement.append_sql(
        " (" <> columns |> string.join(", ") <> ")",
      )
  }
}

/// Generates `INSERT INTO … SELECT … WHERE NOT EXISTS (SELECT 1 FROM … FOR UPDATE)`
/// for 🦭MariaDB and 🐬MySQL when the conflict strategy is `InsertConflictIgnore`.
///
/// Falls back to `INSERT IGNORE` when:
/// - the conflict target is a named constraint (no column names to build
///   the `WHERE` predicate from), or
/// - the insert source is not a concrete list of rows (query / DEFAULT).
///
/// The `WHERE` index predicate carried by `InsertConflictIgnore` has no
/// MariaDB/MySQL equivalent and is silently dropped in both paths.
///
fn insert_conflict_ignore_maria_mysql_apply(
  prepared_statement prepared_statement: PreparedStatement,
  insert insert: Insert(a),
) -> PreparedStatement {
  case insert.table, insert.columns, insert.on_conflict {
    InsertIntoTable(name: table_name),
      InsertColumns(columns: col_names),
      InsertConflictIgnore(
        target: InsertConflictTarget(columns: target_cols),
        ..,
      )
    -> {
      let row_values = case insert.source {
        InsertSourceRows(rows) ->
          rows
          |> list.map(fn(r) {
            let InsertRow(row) = r
            row
          })
        InsertSourceRecords(records: records, encoder: encoder) ->
          records
          |> list.map(fn(r) {
            let InsertRow(row) = r |> encoder
            row
          })
        _ -> []
      }
      case row_values {
        [] ->
          // Non-row source: fall back to INSERT IGNORE
          prepared_statement
          |> insert_ignore_into_table_apply(insert.table)
          |> insert_columns_apply(insert.columns)
          |> insert_modifier_apply(insert.modifier)
          |> insert_source_apply(insert.source)
        _ ->
          prepared_statement
          |> insert_into_table_apply(insert.table)
          |> insert_columns_apply(insert.columns)
          |> insert_modifier_apply(insert.modifier)
          |> insert_select_not_exists_rows_apply(
            row_values,
            col_names,
            table_name,
            target_cols,
          )
      }
    }
    // Constraint-based target or missing table/columns: fall back to INSERT IGNORE
    _, _, _ ->
      prepared_statement
      |> insert_ignore_into_table_apply(insert.table)
      |> insert_columns_apply(insert.columns)
      |> insert_modifier_apply(insert.modifier)
      |> insert_source_apply(insert.source)
  }
}

/// Emits one `SELECT val, … WHERE NOT EXISTS (…)` per row, joined by
/// `UNION ALL`, so the whole batch can be wrapped in a single `INSERT INTO`.
///
fn insert_select_not_exists_rows_apply(
  prepared_statement prepared_statement: PreparedStatement,
  rows rows: List(List(InsertValue)),
  col_names col_names: List(String),
  table_name table_name: String,
  target_cols target_cols: List(String),
) -> PreparedStatement {
  rows
  |> list.fold(prepared_statement, fn(new_prepared_statement, values) {
    let new_prepared_statement = case
      new_prepared_statement == prepared_statement
    {
      True ->
        new_prepared_statement
        |> prepared_statement.append_sql(" SELECT ")
      False ->
        new_prepared_statement
        |> prepared_statement.append_sql(" UNION ALL SELECT ")
    }
    new_prepared_statement
    |> row_apply(values)
    |> insert_not_exists_where_apply(values, col_names, table_name, target_cols)
  })
}

/// Appends `WHERE NOT EXISTS (SELECT 1 FROM <table> WHERE <col> = ? … FOR UPDATE)`
/// and re-emits the target-column parameter values so they appear in the
/// prepared-statement param list a second time.
///
fn insert_not_exists_where_apply(
  prepared_statement prepared_statement: PreparedStatement,
  row_values row_values: List(InsertValue),
  col_names col_names: List(String),
  table_name table_name: String,
  target_cols target_cols: List(String),
) -> PreparedStatement {
  let target_col_values =
    list.zip(col_names, row_values)
    |> list.filter(fn(pair) { list.contains(target_cols, pair.0) })

  case target_col_values {
    [] -> prepared_statement
    _ -> {
      let prepared_statement =
        prepared_statement
        |> prepared_statement.append_sql(
          " WHERE NOT EXISTS (SELECT 1 FROM " <> table_name <> " WHERE ",
        )
      let prepared_statement =
        target_col_values
        |> list.fold(prepared_statement, fn(new_prepared_statement, pair) {
          let #(col_name, insert_value) = pair
          let new_prepared_statement = case
            new_prepared_statement == prepared_statement
          {
            True -> new_prepared_statement
            False ->
              new_prepared_statement
              |> prepared_statement.append_sql(" AND ")
          }
          case insert_value {
            InsertParam(param) ->
              new_prepared_statement
              |> prepared_statement.append_sql(col_name <> " = ")
              |> prepared_statement.append_param(param)
            InsertDefault -> new_prepared_statement
            InsertFragment(fragment) ->
              new_prepared_statement
              |> prepared_statement.append_sql(col_name <> " = ")
              |> read_query.fragment_apply(fragment)
          }
        })
      prepared_statement
      |> prepared_statement.append_sql(" FOR UPDATE)")
    }
  }
}

fn insert_modifier_apply(
  prepared_statement prepared_statement: PreparedStatement,
  insert_modifer insert_modifier: InsertModifier,
) -> PreparedStatement {
  case insert_modifier {
    NoInsertModifier -> prepared_statement
    InsertModifier(modifier:) ->
      prepared_statement |> prepared_statement.append_sql(" " <> modifier)
  }
}

fn insert_source_apply(
  prepared_statement prepared_statement: PreparedStatement,
  source source: InsertSource(a),
) -> PreparedStatement {
  case source {
    NoInsertSource -> prepared_statement
    InsertSourceRecords(records: source, encoder: row_encoder) ->
      prepared_statement
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_params_apply(source:, row_encoder:)
    InsertSourceRows(rows: source) ->
      prepared_statement
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_values_apply(source:)
    InsertSourceQuery(query:) ->
      prepared_statement
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_query_apply(query:)
    InsertSourceDefault ->
      prepared_statement |> prepared_statement.append_sql(" DEFAULT VALUES")
  }
}

fn insert_from_params_apply(
  prepared_statement prepared_statement: PreparedStatement,
  source source: List(a),
  row_encoder row_encoder: fn(a) -> InsertRow,
) {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" (")
  let prepared_statement =
    source
    |> list.fold(
      prepared_statement,
      fn(new_prepared_statement: PreparedStatement, record: a) -> PreparedStatement {
        let InsertRow(row) = record |> row_encoder
        case new_prepared_statement == prepared_statement {
          True -> new_prepared_statement |> row_apply(row)
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql("), (")
            |> row_apply(row)
        }
      },
    )
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(")")

  prepared_statement
}

fn insert_from_values_apply(
  prepared_statement prepared_statement: PreparedStatement,
  source source: List(InsertRow),
) {
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(" (")
  let prepared_statement =
    source
    |> list.fold(
      prepared_statement,
      fn(new_prepared_statement: PreparedStatement, row: InsertRow) -> PreparedStatement {
        let InsertRow(row) = row
        case new_prepared_statement == prepared_statement {
          True -> new_prepared_statement |> row_apply(row)
          False ->
            new_prepared_statement
            |> prepared_statement.append_sql("), (")
            |> row_apply(row)
        }
      },
    )
  let prepared_statement =
    prepared_statement |> prepared_statement.append_sql(")")

  prepared_statement
}

fn row_apply(
  new_prepared_statement: PreparedStatement,
  row: List(InsertValue),
) -> PreparedStatement {
  row
  |> list.fold(
    new_prepared_statement,
    fn(
      new_prepared_statement_inner: PreparedStatement,
      insert_value: InsertValue,
    ) -> PreparedStatement {
      case insert_value {
        InsertParam(param:) -> {
          case new_prepared_statement_inner == new_prepared_statement {
            True ->
              new_prepared_statement_inner
              |> prepared_statement.append_param(param)
            False ->
              new_prepared_statement_inner
              |> prepared_statement.append_sql(", ")
              |> prepared_statement.append_param(param)
          }
        }
        InsertDefault -> {
          case new_prepared_statement_inner == new_prepared_statement {
            True ->
              new_prepared_statement_inner
              |> prepared_statement.append_sql("DEFAULT")
            False ->
              new_prepared_statement_inner
              |> prepared_statement.append_sql(", DEFAULT")
          }
        }
        InsertFragment(fragment:) -> {
          case new_prepared_statement_inner == new_prepared_statement {
            True ->
              new_prepared_statement_inner
              |> read_query.fragment_apply(fragment)
            False ->
              new_prepared_statement_inner
              |> prepared_statement.append_sql(", ")
              |> read_query.fragment_apply(fragment)
          }
        }
      }
    },
  )
}

fn insert_from_query_apply(
  prepared_statement prepared_statement: PreparedStatement,
  query query: ReadQuery,
) {
  prepared_statement
  |> prepared_statement.append_sql(" (")
  |> read_query.apply(query)
  |> prepared_statement.append_sql(")")
}

fn insert_on_conflict_apply(
  prepared_statement prepared_statement: PreparedStatement,
  on_conflict_strategy on_conflict: InsertConflictStrategy(a),
) {
  case on_conflict {
    InsertConflictError -> prepared_statement
    InsertConflictIgnore(target:, where:) ->
      prepared_statement
      |> prepared_statement.append_sql(" ON CONFLICT (")
      |> insert_on_conflict_target_apply(target)
      |> prepared_statement.append_sql(")")
      |> read_query.where_clause_apply(where)
      |> prepared_statement.append_sql(" DO NOTHING")
    InsertConflictUpdate(target: target, where:, update:) ->
      prepared_statement
      |> prepared_statement.append_sql(" ON CONFLICT (")
      |> insert_on_conflict_target_apply(target)
      |> prepared_statement.append_sql(")")
      |> prepared_statement.append_sql(" DO ")
      |> update_apply(update)
      |> read_query.where_clause_apply(where)
  }
}

fn insert_on_conflict_target_apply(
  prepared_statement prepared_statement: PreparedStatement,
  target target: InsertConflictTarget,
) {
  case target {
    InsertConflictTarget(columns:) ->
      prepared_statement
      |> prepared_statement.append_sql(columns |> string.join(", "))
    InsertConflictTargetConstraint(constraint:) ->
      prepared_statement |> prepared_statement.append_sql(constraint)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Update                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Represents an `UPDATE` statement.
///
/// NOTICE: 🐘PostgreSQL and 🪶SQLite only support `JOIN` in `UPDATE` if `FROM`
/// is also given.
///
pub type Update(a) {
  Update(
    // with (_recursive?): ?, // v2
    table: UpdateTable,
    modifier: UpdateModifier,
    sets: UpdateSets,
    from: From,
    join: Joins,
    where: Where,
    returning: Returning,
    epilog: Epilog,
    comment: Comment,
  )
}

/// Sets an `UPDATE` modifier.
///
pub type UpdateModifier {
  NoUpdateModifier
  UpdateModifier(modifier: String)
}

/// Specifies the table to `UPDATE`.
///
pub type UpdateTable {
  NoUpdateTable
  UpdateTable(String)
}

/// Specifies the columns to `UPDATE` and their values.
///
pub type UpdateSets {
  NoUpdateSets
  UpdateSets(List(UpdateSet))
}

/// Specifies an update set
///
pub type UpdateSet {
  UpdateParamSet(column: String, param: Param)
  UpdateExpressionSet(columns: List(String), expression: String)
  UpdateSubQuerySet(columns: List(String), query: ReadQuery)
  /// A fragment set, e.g. `fragment.prepared("$::uuid", [fragment.string(id)])`.
  /// Allows type casts and parameterized expressions in UPDATE SET,
  /// which for instance 🐘Postgres may require.
  UpdateFragmentSet(column: String, fragment: Fragment)
}

fn update_apply(
  prepared_statement prepared_statement: PreparedStatement,
  update update: Update(a),
) {
  prepared_statement
  |> prepared_statement.append_sql("UPDATE")
  |> update_table_apply(update.table)
  |> update_modifier_apply(update.modifier)
  |> prepared_statement.append_sql(" SET")
  |> update_set_apply(update.sets)
  |> read_query.from_clause_apply(update.from)
  |> read_query.join_clause_apply(update.join)
  |> read_query.where_clause_apply(update.where)
  |> returning_apply(update.returning)
  |> read_query.comment_apply(update.comment)
  |> read_query.epilog_apply(update.epilog)
}

fn update_table_apply(
  prepared_statement prepared_statement: PreparedStatement,
  table_name table_name: UpdateTable,
) -> PreparedStatement {
  case table_name {
    NoUpdateTable -> prepared_statement
    UpdateTable(table) ->
      prepared_statement
      |> prepared_statement.append_sql(" " <> table)
  }
}

fn update_modifier_apply(
  prepared_statement prepared_statement: PreparedStatement,
  update_modifier update_modifier: UpdateModifier,
) -> PreparedStatement {
  case update_modifier {
    NoUpdateModifier -> prepared_statement
    UpdateModifier(modifier:) ->
      prepared_statement |> prepared_statement.append_sql(" " <> modifier)
  }
}

fn update_set_apply(
  prepared_statement prepared_statement: PreparedStatement,
  update_sets update_sets: UpdateSets,
) -> PreparedStatement {
  case update_sets {
    NoUpdateSets -> prepared_statement
    UpdateSets(update_sets) ->
      prepared_statement |> update_sets_apply(update_sets)
  }
}

fn update_sets_apply(
  prepared_statement prepared_statement: PreparedStatement,
  update_sets update_sets: List(UpdateSet),
) -> PreparedStatement {
  let columns_apply = fn(
    new_prepared_statement: PreparedStatement,
    columns: List(String),
  ) -> PreparedStatement {
    case columns {
      [] -> new_prepared_statement
      [column] ->
        new_prepared_statement
        |> prepared_statement.append_sql(" " <> column <> " =")
      [_column, ..] ->
        new_prepared_statement
        |> prepared_statement.append_sql(
          " (" <> columns |> string.join(", ") <> ")",
        )
        |> prepared_statement.append_sql(" =")
    }
  }

  update_sets
  |> list.fold(
    prepared_statement,
    fn(new_prepared_statement: PreparedStatement, update_set: UpdateSet) -> PreparedStatement {
      let new_prepared_statement = case
        new_prepared_statement == prepared_statement
      {
        True -> new_prepared_statement
        False -> new_prepared_statement |> prepared_statement.append_sql(",")
      }
      case update_set {
        UpdateParamSet(column:, param:) ->
          new_prepared_statement
          |> columns_apply([column])
          |> prepared_statement.append_sql(" ")
          |> prepared_statement.append_param(param)
        UpdateExpressionSet(columns:, expression:) ->
          new_prepared_statement
          |> columns_apply(columns)
          |> prepared_statement.append_sql(" " <> expression)
        UpdateSubQuerySet(columns:, query:) ->
          new_prepared_statement
          |> columns_apply(columns)
          |> prepared_statement.append_sql(" (")
          |> read_query.apply(query)
          |> prepared_statement.append_sql(")")
        UpdateFragmentSet(column:, fragment:) ->
          new_prepared_statement
          |> columns_apply([column])
          |> prepared_statement.append_sql(" ")
          |> read_query.fragment_apply(fragment)
      }
    },
  )
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │ Delete                                                                    │
// └───────────────────────────────────────────────────────────────────────────┘

/// Represents a `DELETE` query.
///
/// NOTICE: 🪶SQLite does not support `USING` in `DELETE`.
///
/// NOTICE: For 🦭MariaDB and 🐬MySQL it is mandatory to specify the table set
/// within the `FROM` clause in the `USING` clause, again - e.g. in raw SQL:
/// `DELETE * FROM a USING a, b, WHERE a.b_id = b.id;`
///
/// NOTICE: 🦭MariaDB and 🐬MySQL may not support sub-queries in the `USING`
/// clause. In such case you may use a sub-query in a `WHERE` clause, or use a ]
/// join instead.
///
pub type Delete(a) {
  Delete(
    // with (_recursive?): ?, // v2
    modifier: DeleteModifier,
    table: DeleteTable,
    using: DeleteUsing,
    join: Joins,
    where: Where,
    returning: Returning,
    epilog: Epilog,
    comment: Comment,
  )
}

/// Specifies the modifier for `DELETE`.
///
pub type DeleteModifier {
  NoDeleteModifier
  DeleteModifier(modifier: String)
}

/// Specifies the table to `DELETE` from.
///
pub type DeleteTable {
  NoDeleteTable
  DeleteTable(name: String)
}

/// Specifies the `USING` clause for `DELETE`.
///
pub type DeleteUsing {
  NoDeleteUsing
  // TODO v2 In case From wraps a list in future
  // ... then this should not be a list anymore.
  DeleteUsing(froms: List(From))
}

fn delete_apply(
  prepared_statement prepared_statement: PreparedStatement,
  delete delete: Delete(a),
) {
  prepared_statement
  |> prepared_statement.append_sql("DELETE")
  |> delete_table_apply(delete.table)
  |> delete_modifier_apply(delete.modifier)
  |> using_apply(delete.using)
  |> read_query.join_clause_apply(delete.join)
  |> read_query.where_clause_apply(delete.where)
  |> returning_apply(delete.returning)
  |> read_query.comment_apply(delete.comment)
  |> read_query.epilog_apply(delete.epilog)
}

fn delete_table_apply(
  prepared_statement prepared_statement: PreparedStatement,
  table_name table_name: DeleteTable,
) -> PreparedStatement {
  case table_name {
    NoDeleteTable -> prepared_statement
    DeleteTable(table) ->
      prepared_statement
      |> prepared_statement.append_sql(" FROM " <> table)
  }
}

fn delete_modifier_apply(
  prepared_statement prepared_statement: PreparedStatement,
  delete_modifer update_modifier: DeleteModifier,
) -> PreparedStatement {
  case update_modifier {
    NoDeleteModifier -> prepared_statement
    DeleteModifier(modifier:) ->
      prepared_statement |> prepared_statement.append_sql(" " <> modifier)
  }
}

fn using_apply(
  prepared_statement prepared_statement: PreparedStatement,
  using using: DeleteUsing,
) -> PreparedStatement {
  case using {
    NoDeleteUsing -> prepared_statement
    DeleteUsing(froms:) -> {
      let prepared_statement =
        prepared_statement |> prepared_statement.append_sql(" USING ")

      froms
      |> list.fold(
        prepared_statement,
        fn(new_prepared_statement: PreparedStatement, from: From) -> PreparedStatement {
          let new_prepared_statement = case
            new_prepared_statement == prepared_statement,
            from
          {
            True, _ | _, NoFrom -> new_prepared_statement
            False, _ ->
              new_prepared_statement |> prepared_statement.append_sql(", ")
          }

          case from {
            NoFrom -> new_prepared_statement
            FromTable(name: table_name) ->
              new_prepared_statement
              |> prepared_statement.append_sql(table_name)
            FromSubQuery(query, alias) ->
              new_prepared_statement
              |> prepared_statement.append_sql(" (")
              |> read_query.apply(query)
              |> prepared_statement.append_sql(") AS " <> alias)
          }
        },
      )
    }
  }
}
