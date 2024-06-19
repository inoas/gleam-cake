//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

import cake/internal/prepared_statement.{
  type DatabaseAdapter, type PreparedStatement,
}
import cake/internal/query.{
  type Comment, type From, type Joins, type Query, type Where, FromSubQuery,
  FromTable, NoFrom,
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
/// While (read) queries never use write queries, write queries can use (read)
/// queries, as they can use subqueries to define the data to be written or for
/// atomic updates or conflict resolution.
///
pub type WriteQuery(a) {
  InsertQuery(Insert(a))
  UpdateQuery(Update(a))
  DeleteQuery(Delete(a))
}

pub fn to_prepared_statement(
  query qry: WriteQuery(a),
  placeholder_prefix prp_stm_prfx: String,
  database_adapter db_adptr: DatabaseAdapter,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new(db_adptr)
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

pub type Insert(a) {
  Insert(
    // with (_recursive?): ?, // v2
    into_table: InsertIntoTable,
    columns: InsertColumns,
    modifier: InsertModifier,
    source: InsertSource(a),
    on_conflict: InsertConflictStrategy(a),
    returning: Returning,
    comment: Comment,
  )
}

pub type InsertIntoTable {
  InsertIntoTable(table: String)
}

pub type InsertColumns {
  InsertColumns(cols: List(String))
}

pub type InsertModifier {
  NoInsertModifier
  InsertModifier(modifier: String)
}

pub type InsertSource(a) {
  InsertSourceDefault
  InsertSourceParams(records: List(a), caster: fn(a) -> InsertRow)
  InsertSourceValues(records: List(InsertRow))
  InsertSourceQuery(query: Query)
}

pub type InsertRow {
  InsertRow(row: List(InsertValue))
}

pub type InsertValue {
  InsertParam(column: String, param: Param)
  InsertDefault(column: String)
}

/// InsertConflictUpdate is also known as `INSERT OR UPDATE` aka `UPSERT`.
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

pub type InsertConfictTarget {
  InsertConflictTarget(columns: List(String))
  InsertConflictTargetConstraint(constraint: String)
}

pub fn to_insert_query(insert: Insert(a)) -> WriteQuery(a) {
  insert |> InsertQuery
}

fn insert_apply(
  prepared_statement prp_stm: PreparedStatement,
  insert isrt: Insert(a),
) {
  let InsertIntoTable(into_table) = isrt.into_table
  let InsertColumns(insert_columns) = isrt.columns

  let prp_stm =
    prp_stm
    |> prepared_statement.append_sql(
      "INSERT INTO "
      <> into_table
      <> " ("
      <> insert_columns |> string.join(", ")
      <> ")",
    )
    |> insert_modifier_apply(isrt.modifier)

  let prp_stm = case isrt.source {
    InsertSourceParams(records: src, caster: cstr) ->
      prp_stm
      |> prepared_statement.append_sql(" VALUES")
      |> insert_from_params_apply(source: src, row_caster: cstr)
    InsertSourceValues(records: src) ->
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

  prp_stm
  |> on_conflict_apply(isrt.on_conflict)
  |> returning_apply(isrt.returning)
  |> query.comment_apply(isrt.comment)
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
  query qry: Query,
) {
  prp_stm
  |> prepared_statement.append_sql(" (")
  |> query.apply(qry)
  |> prepared_statement.append_sql(")")
}

fn on_conflict_apply(
  prepared_statement prp_stm: PreparedStatement,
  on_conflict_strategy on_cnf: InsertConflictStrategy(a),
) {
  case on_cnf {
    InsertConflictError -> prp_stm
    InsertConflictIgnore(target: cflt_trgt, where: whr) ->
      prp_stm
      |> prepared_statement.append_sql(" ON CONFLICT")
      |> on_conflict_target_apply(cflt_trgt)
      |> query.where_clause_apply(whr)
      |> prepared_statement.append_sql(" DO NOTHING")
    InsertConflictUpdate(target: cflt_trgt, where: whr, update: upt) ->
      prp_stm
      |> prepared_statement.append_sql(" ON CONFLICT (")
      |> on_conflict_target_apply(cflt_trgt)
      |> query.where_clause_apply(whr)
      |> prepared_statement.append_sql(" DO ")
      |> update_apply(upt)
  }
}

fn on_conflict_target_apply(
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

/// NOTICE: Postgres only supports `Joins` if `From` is given.
///
pub type Update(a) {
  Update(
    // with (_recursive?): ?, // v2
    modifier: UpdateModifier,
    table: UpdateTable,
    set: UpdateSets,
    from: UpdateFrom,
    where: Where,
    returning: Returning,
    comment: Comment,
  )
}

pub type UpdateModifier {
  NoUpdateModifier
  UpdateModifier(modifier: String)
}

pub type UpdateTable {
  UpdateTable(String)
}

pub type UpdateSets {
  UpdateSets(List(UpdateSet))
}

pub type UpdateFrom {
  NoUpdateFrom
  UpdateFrom(from: From)
  UpdateFromJoins(from: From, joins: Joins)
}

pub type UpdateSet {
  UpdateExpressionPairs(columns: List(String), expression: UpdateValue)
  UpdateSubQueryPairs(columns: List(String), value: Query)
}

pub type UpdateValue {
  UpdateExpression(expression: String)
  UpdateParam(param: Param)
}

pub fn update_to_write_query(insert: Update(a)) -> WriteQuery(a) {
  insert |> UpdateQuery
}

fn update_apply(
  prepared_statement prp_stm: PreparedStatement,
  update updt: Update(a),
) {
  let UpdateTable(updt_tbl) = updt.table
  let UpdateSets(updt_sets) = updt.set

  prp_stm
  |> prepared_statement.append_sql("UPDATE " <> updt_tbl)
  |> update_modifier_apply(updt.modifier)
  |> prepared_statement.append_sql(" SET")
  |> update_sets_apply(updt_sets)
  |> update_from_apply(updt.from)
  |> query.where_clause_apply(updt.where)
  |> returning_apply(updt.returning)
  |> query.comment_apply(updt.comment)
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

fn update_sets_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_sets updt_sts: List(UpdateSet),
) {
  let apply_columns = fn(new_prp_stm: PreparedStatement, columns: List(String)) -> PreparedStatement {
    new_prp_stm
    |> prepared_statement.append_sql(
      " (" <> columns |> string.join(", ") <> ")",
    )
    |> prepared_statement.append_sql(" =")
  }

  updt_sts
  |> list.fold(
    prp_stm,
    fn(new_prp_stm: PreparedStatement, updt_st: UpdateSet) -> PreparedStatement {
      case updt_st {
        UpdateExpressionPairs(columns: columns, expression: expression) ->
          new_prp_stm
          |> apply_columns(columns)
          |> prepared_statement.append_sql(" ")
          |> update_expression_apply(expression)
        UpdateSubQueryPairs(columns: columns, value: value) ->
          prp_stm
          |> apply_columns(columns)
          |> prepared_statement.append_sql(" (")
          |> query.apply(value)
          |> prepared_statement.append_sql(")")
      }
    },
  )
}

fn update_from_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_from updt_frm: UpdateFrom,
) -> PreparedStatement {
  case updt_frm {
    NoUpdateFrom -> prp_stm
    UpdateFrom(from: frm) -> prp_stm |> query.from_clause_apply(frm)
    UpdateFromJoins(from: frm, joins: jns) ->
      prp_stm |> query.from_clause_apply(frm) |> query.join_clause_apply(jns)
  }
}

fn update_expression_apply(
  prepared_statement prp_stm: PreparedStatement,
  update_value updt_vl: UpdateValue,
) -> PreparedStatement {
  case updt_vl {
    UpdateExpression(expression: expr) ->
      prp_stm |> prepared_statement.append_sql(expr)
    UpdateParam(param: param) ->
      prp_stm |> prepared_statement.append_param(param)
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Delete                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

/// SQlite does not support `Joins` in `Delete`.
///
pub type Delete(a) {
  Delete(
    // with (_recursive?): ?, // v2
    modifier: DeleteModifier,
    table: DeleteTable,
    using: Using,
    where: Where,
    returning: Returning,
    comment: Comment,
  )
}

pub type DeleteModifier {
  NoDeleteModifier
  DeleteModifier(modifier: String)
}

pub type DeleteTable {
  DeleteTable(name: String)
}

pub type Using {
  NoUsing
  Using(froms: List(From))
}

pub fn delete_to_write_query(insert: Delete(a)) -> WriteQuery(a) {
  insert |> DeleteQuery
}

fn delete_apply(
  prepared_statement prp_stm: PreparedStatement,
  delete dlt: Delete(a),
) {
  let DeleteTable(dlt_tbl) = dlt.table

  prp_stm
  |> prepared_statement.append_sql("DELETE " <> dlt_tbl)
  |> delete_modifier_apply(dlt.modifier)
  |> using_apply(dlt.using)
  |> query.where_clause_apply(dlt.where)
  |> returning_apply(dlt.returning)
  |> query.comment_apply(dlt.comment)
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
  using updt_usng: Using,
) -> PreparedStatement {
  case updt_usng {
    NoUsing -> prp_stm
    Using(froms: frms) -> {
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
              |> query.apply(qry)
              |> prepared_statement.append_sql(") AS " <> als)
          }
        },
      )
    }
  }
}
