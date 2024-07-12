//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

// TODO v3 Add to query validator?

import cake/internal/dialect.{type Dialect}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{
  type Comment, type Epilog, type From, type Joins, type ReadQuery, type Where,
  Epilog, FromSubQuery, FromTable, NoFrom,
}
import cake/param.{type Param}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Write Query                                                              │
// └───────────────────────────────────────────────────────────────────────────┘

/// Write queries encapsulate the different types of write operations
/// in SQL Databases, such as `INSERT`, `UPDATE` and `DELETE`.
///
/// While read queries never use write queries, write queries can use read
/// queries, as they can use subqueries to define the data to be written or for
/// atomic updates or conflict resolution.
///
pub type WriteQuery(a) {
  InsertQuery(Insert(a))
  UpdateQuery(Update(a))
  DeleteQuery(Delete(a))
}

/// Converts a `WriteQuery` into a `PreparedStatement`.
///
pub fn to_prepared_statement(
  query qry: WriteQuery(a),
  placeholder_base plchldr_bs: String,
  dialect dlct: Dialect,
) -> PreparedStatement {
  plchldr_bs
  |> prepared_statement.new(dlct)
  |> apply(qry)
}

fn apply(
  prepared_statement prp_stm: PreparedStatement,
  query qry: WriteQuery(a),
) -> PreparedStatement {
  case qry {
    InsertQuery(insert) -> prp_stm |> insert_apply(insert)
    UpdateQuery(update) -> prp_stm |> update_apply(update)
    DeleteQuery(delete) -> prp_stm |> delete_apply(delete)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Returning                                                                │
// └───────────────────────────────────────────────────────────────────────────┘

/// `Returning` is used to define the columns to be returned after a write query
/// has been executed.
///
pub type Returning {
  NoReturning
  Returning(columns: List(String))
}

fn returning_apply(
  prepared_statement prp_stm: PreparedStatement,
  returning rtrn: Returning,
) -> PreparedStatement {
  case rtrn {
    NoReturning -> prp_stm
    Returning(columns: cols) ->
      prp_stm
      |> prepared_statement.append_sql(" RETURNING ")
      |> prepared_statement.append_sql(cols |> string.join(", "))
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Insert                                                                   │
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
  InsertSourceRecords(records: List(a), caster: fn(a) -> InsertRow)
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
  InsertParam(column: String, param: Param)
  InsertDefault(column: String)
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
  InsertConflictIgnore(target: InsertConfictTarget, where: Where)
  InsertConflictUpdate(
    target: InsertConfictTarget,
    where: Where,
    update: Update(a),
  )
}

/// The `InsertConfictTarget` type is used to define the target of the conflict
/// resolution.
///
pub type InsertConfictTarget {
  InsertConflictTarget(columns: List(String))
  InsertConflictTargetConstraint(constraint: String)
}

fn insert_apply(
  prepared_statement prp_stm: PreparedStatement,
  insert isrt: Insert(a),
) {
  prp_stm
  |> insert_into_table_apply(isrt.table)
  |> insert_columns_apply(isrt.columns)
  |> insert_modifier_apply(isrt.modifier)
  |> insert_source_apply(isrt.source)
  |> insert_on_conflict_apply(isrt.on_conflict)
  |> returning_apply(isrt.returning)
  |> read_query.comment_apply(isrt.comment)
  |> read_query.epilog_apply(isrt.epilog)
}

fn insert_into_table_apply(
  prepared_statement prp_stm: PreparedStatement,
  table tbl: InsertIntoTable,
) -> PreparedStatement {
  case tbl {
    NoInsertIntoTable -> prp_stm |> prepared_statement.append_sql("INSERT INTO")
    InsertIntoTable(name: tbl_name) ->
      prp_stm |> prepared_statement.append_sql("INSERT INTO " <> tbl_name)
  }
}

fn insert_columns_apply(
  prepared_statement prp_stm: PreparedStatement,
  columns cols: InsertColumns,
) -> PreparedStatement {
  case cols {
    NoInsertColumns -> prp_stm
    InsertColumns(columns: cols) ->
      prp_stm
      |> prepared_statement.append_sql(" (" <> cols |> string.join(", ") <> ")")
  }
}

fn insert_modifier_apply(
  prepared_statement prp_stm: PreparedStatement,
  insert_modifer isrt_mdfr: InsertModifier,
) -> PreparedStatement {
  case isrt_mdfr {
    NoInsertModifier -> prp_stm
    InsertModifier(modifier: mdfr) ->
      prp_stm |> prepared_statement.append_sql(" " <> mdfr)
  }
}

fn insert_source_apply(
  prepared_statement prp_stm: PreparedStatement,
  source src: InsertSource(a),
) -> PreparedStatement {
  case src {
    NoInsertSource -> prp_stm
    InsertSourceRecords(records: src, caster: cstr) ->
      prp_stm
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_params_apply(source: src, row_caster: cstr)
    InsertSourceRows(rows: src) ->
      prp_stm
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_values_apply(source: src)
    InsertSourceQuery(query: qry) ->
      prp_stm
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_query_apply(query: qry)
    InsertSourceDefault ->
      prp_stm |> prepared_statement.append_sql(" DEFAULT VALUES")
  }
}

fn insert_from_params_apply(
  prepared_statement prp_stm: PreparedStatement,
  source src: List(a),
  row_caster cstr: fn(a) -> InsertRow,
) {
  let prp_stm = prp_stm |> prepared_statement.append_sql(" (")
  let prp_stm =
    src
    |> list.fold(
      prp_stm,
      fn(new_prp_stm: PreparedStatement, rcrd: a) -> PreparedStatement {
        let InsertRow(row) = rcrd |> cstr
        case new_prp_stm == prp_stm {
          True -> new_prp_stm |> row_apply(row)
          False ->
            new_prp_stm
            |> prepared_statement.append_sql("), (")
            |> row_apply(row)
        }
      },
    )
  let prp_stm = prp_stm |> prepared_statement.append_sql(")")

  prp_stm
}

fn insert_from_values_apply(
  prepared_statement prp_stm: PreparedStatement,
  source src: List(InsertRow),
) {
  let prp_stm = prp_stm |> prepared_statement.append_sql(" (")
  let prp_stm =
    src
    |> list.fold(
      prp_stm,
      fn(new_prp_stm: PreparedStatement, row: InsertRow) -> PreparedStatement {
        let InsertRow(row) = row
        case new_prp_stm == prp_stm {
          True -> new_prp_stm |> row_apply(row)
          False ->
            new_prp_stm
            |> prepared_statement.append_sql("), (")
            |> row_apply(row)
        }
      },
    )
  let prp_stm = prp_stm |> prepared_statement.append_sql(")")

  prp_stm
}

fn row_apply(
  new_prp_stm: PreparedStatement,
  row: List(InsertValue),
) -> PreparedStatement {
  row
  |> list.fold(
    new_prp_stm,
    fn(new_prp_stm_inner: PreparedStatement, insert_value: InsertValue) -> PreparedStatement {
      case insert_value {
        // TODO v1: What is _column for here?
        InsertParam(column: _column, param: param) -> {
          case new_prp_stm_inner == new_prp_stm {
            True ->
              new_prp_stm_inner
              |> prepared_statement.append_param(param)
            False ->
              new_prp_stm_inner
              |> prepared_statement.append_sql(", ")
              |> prepared_statement.append_param(param)
          }
        }
        // TODO v1: What is _column for here?
        InsertDefault(column: _column) -> {
          case new_prp_stm_inner == new_prp_stm {
            True ->
              new_prp_stm_inner
              |> prepared_statement.append_sql("DEFAULT")
            False ->
              new_prp_stm_inner
              |> prepared_statement.append_sql(", DEFAULT")
          }
        }
      }
    },
  )
}

fn insert_from_query_apply(
  prepared_statement prp_stm: PreparedStatement,
  query qry: ReadQuery,
) {
  prp_stm
  |> prepared_statement.append_sql(" (")
  |> read_query.apply(qry)
  |> prepared_statement.append_sql(")")
}

fn insert_on_conflict_apply(
  prepared_statement prp_stm: PreparedStatement,
  on_conflict_strategy on_cnf: InsertConflictStrategy(a),
) {
  case on_cnf {
    InsertConflictError -> prp_stm
    InsertConflictIgnore(target: cflt_trgt, where: whr) ->
      prp_stm
      |> prepared_statement.append_sql(" ON CONFLICT (")
      |> insert_on_conflict_target_apply(cflt_trgt)
      |> prepared_statement.append_sql(")")
      |> prepared_statement.append_sql(" DO NOTHING")
      |> read_query.where_clause_apply(whr)
    InsertConflictUpdate(target: cflt_trgt, where: whr, update: upt) ->
      prp_stm
      |> prepared_statement.append_sql(" ON CONFLICT (")
      |> insert_on_conflict_target_apply(cflt_trgt)
      |> prepared_statement.append_sql(")")
      |> prepared_statement.append_sql(" DO ")
      |> update_apply(upt)
      |> read_query.where_clause_apply(whr)
  }
}

fn insert_on_conflict_target_apply(
  prepared_statement prp_stm: PreparedStatement,
  target cflt_trgt: InsertConfictTarget,
) {
  case cflt_trgt {
    InsertConflictTarget(columns: cols) ->
      prp_stm |> prepared_statement.append_sql(cols |> string.join(", "))
    InsertConflictTargetConstraint(constraint: cnstrnt) ->
      prp_stm |> prepared_statement.append_sql(cnstrnt)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Update                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Represents an `UPDATE` statement.
///
/// NOTICE: Postgres and SQLite only support `JOIN` in `UPDATE` if `FROM` is
/// also given.
///
pub type Update(a) {
  Update(
    // with (_recursive?): ?, // v2
    table: UpdateTable,
    modifier: UpdateModifier,
    set: UpdateSets,
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
  UpdateSubQuerySet(columns: List(String), sub_query: ReadQuery)
}

fn update_apply(
  prepared_statement prp_stm: PreparedStatement,
  update updt: Update(a),
) {
  prp_stm
  |> prepared_statement.append_sql("UPDATE")
  |> update_table_apply(updt.table)
  |> update_modifier_apply(updt.modifier)
  |> prepared_statement.append_sql(" SET")
  |> update_set_apply(updt.set)
  |> read_query.from_clause_apply(updt.from)
  |> read_query.join_clause_apply(updt.join)
  |> read_query.where_clause_apply(updt.where)
  |> returning_apply(updt.returning)
  |> read_query.comment_apply(updt.comment)
  |> read_query.epilog_apply(updt.epilog)
}

fn update_table_apply(
  prepared_statement prp_stm: PreparedStatement,
  table tbl: UpdateTable,
) -> PreparedStatement {
  case tbl {
    NoUpdateTable -> prp_stm
    UpdateTable(tbl) ->
      prp_stm
      |> prepared_statement.append_sql(" " <> tbl)
  }
}

fn update_modifier_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_modifer updt_mdfr: UpdateModifier,
) -> PreparedStatement {
  case updt_mdfr {
    NoUpdateModifier -> prp_stm
    UpdateModifier(modifier: mdfr) ->
      prp_stm |> prepared_statement.append_sql(" " <> mdfr)
  }
}

fn update_set_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_sets updt_sts: UpdateSets,
) -> PreparedStatement {
  case updt_sts {
    NoUpdateSets -> prp_stm
    UpdateSets(updt_sets) -> prp_stm |> update_sets_apply(updt_sets)
  }
}

fn update_sets_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_sets updt_sts: List(UpdateSet),
) -> PreparedStatement {
  let apply_columns = fn(new_prp_stm: PreparedStatement, cols: List(String)) -> PreparedStatement {
    case cols {
      [] -> new_prp_stm
      [col] -> new_prp_stm |> prepared_statement.append_sql(" " <> col <> " =")
      [_col, ..] ->
        new_prp_stm
        |> prepared_statement.append_sql(
          " (" <> cols |> string.join(", ") <> ")",
        )
        |> prepared_statement.append_sql(" =")
    }
  }

  updt_sts
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, updt_st: UpdateSet) -> PreparedStatement {
      let new_prp_stm = case new_prp_stm == prp_stm {
        True -> new_prp_stm
        False -> new_prp_stm |> prepared_statement.append_sql(",")
      }
      case updt_st {
        UpdateParamSet(column: col, param: prm) ->
          new_prp_stm
          |> apply_columns([col])
          |> prepared_statement.append_sql(" ")
          |> prepared_statement.append_param(prm)
        UpdateExpressionSet(columns: cols, expression: expr) ->
          new_prp_stm
          |> apply_columns(cols)
          |> prepared_statement.append_sql(" " <> expr)
        UpdateSubQuerySet(columns: cols, sub_query: qry) ->
          new_prp_stm
          |> apply_columns(cols)
          |> prepared_statement.append_sql(" (")
          |> read_query.apply(qry)
          |> prepared_statement.append_sql(")")
      }
    },
  )
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Delete                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// Represents a `DELETE` query.
///
/// NOTICE: SQLite does not support `USING` in `DELETE`.
///
/// NOTICE: For MariaDB and MySQL it is mandatory to specify the table specified
/// in the `FROM` clause in the `USING` clause, again - e.g. in raw SQL:
/// `DELETE * FROM a USING a, b, WHERE a.b_id = b.id;`
///
/// NOTICE: MariaDB and MySQL may not support sub-queries in the `USING` clause.
/// In such case you may use a sub-query in a `WHERE` clause, or use a join
/// instead.
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
  prepared_statement prp_stm: PreparedStatement,
  delete dlt: Delete(a),
) {
  prp_stm
  |> prepared_statement.append_sql("DELETE")
  |> delete_table_apply(dlt.table)
  |> delete_modifier_apply(dlt.modifier)
  |> using_apply(dlt.using)
  |> read_query.join_clause_apply(dlt.join)
  |> read_query.where_clause_apply(dlt.where)
  |> returning_apply(dlt.returning)
  |> read_query.comment_apply(dlt.comment)
  |> read_query.epilog_apply(dlt.epilog)
}

fn delete_table_apply(
  prepared_statement prp_stm: PreparedStatement,
  table tbl: DeleteTable,
) -> PreparedStatement {
  case tbl {
    NoDeleteTable -> prp_stm
    DeleteTable(tbl) ->
      prp_stm
      |> prepared_statement.append_sql(" FROM " <> tbl)
  }
}

fn delete_modifier_apply(
  prepared_statement prp_stm: PreparedStatement,
  delete_modifer updt_mdfr: DeleteModifier,
) -> PreparedStatement {
  case updt_mdfr {
    NoDeleteModifier -> prp_stm
    DeleteModifier(modifier: mdfr) ->
      prp_stm |> prepared_statement.append_sql(" " <> mdfr)
  }
}

fn using_apply(
  prepared_statement prp_stm: PreparedStatement,
  using updt_usng: DeleteUsing,
) -> PreparedStatement {
  case updt_usng {
    NoDeleteUsing -> prp_stm
    DeleteUsing(froms: frms) -> {
      let prp_stm = prp_stm |> prepared_statement.append_sql(" USING ")

      frms
      |> list.fold(
        prp_stm,
        fn(new_prp_stm: PreparedStatement, frm: From) -> PreparedStatement {
          let new_prp_stm = case new_prp_stm == prp_stm, frm {
            True, _ | _, NoFrom -> new_prp_stm
            False, _ -> new_prp_stm |> prepared_statement.append_sql(", ")
          }

          case frm {
            NoFrom -> new_prp_stm
            FromTable(name: tbl) ->
              new_prp_stm |> prepared_statement.append_sql(tbl)
            FromSubQuery(qry, als) ->
              prp_stm
              |> prepared_statement.append_sql(" (")
              |> read_query.apply(qry)
              |> prepared_statement.append_sql(") AS " <> als)
          }
        },
      )
    }
  }
}
