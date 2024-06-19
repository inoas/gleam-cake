//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

import cake/internal/prepared_statement.{
  type DatabaseAdapter, type PreparedStatement,
}
import cake/internal/query.{type Comment, type Query}
import cake/param.{type Param}
import gleam/list
import gleam/string

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  WriteQuery                                                               │
// └───────────────────────────────────────────────────────────────────────────┘

pub type WriteQuery(a) {
  InsertQuery(Insert(a))
  // UpdateQuery(Update(a))
  // UpdateAllQuery(UpdateAll(a))
  // DeleteQuery
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
  }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Insert                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

pub type InsertConflictStrategy {
  // TODO v1: implement SQL generation for RDMBS
  InsertConflictError
  // TODO v1: implement SQL generation for RDMBS
  InsertConflictIgnore
  // TODO v1: implement SQL generation for RDMBS
  // TODO v1: change update from String to cake Update type once we have it
  InsertConflictUpdate(command: String, update: String)
}

pub type Insert(a) {
  Insert(
    // with (_recursive?): ?, // v2
    into: String,
    columns: List(String),
    // TODO v1: implement SQL string injection
    values_modifier: InsertValuesModifier,
    source: InsertRecords(a),
    // TODO v1: implement SQL generation for RDMBS
    on_conflict: InsertConflictStrategy,
    comment: Comment,
  )
}

pub type InsertModifier {
  NoInsertModifier
  InsertModifier(modifier: String)
}

pub type InsertValuesModifier {
  NoInsertValuesModifier
  InsertValuesModifier(modifier: String)
}

pub type InsertRecords(a) {
  InsertFromParams(source: List(a), caster: fn(a) -> InsertRow)
  InsertFromQuery(query: Query)
}

pub type InsertRow {
  InsertRow(row: List(InsertValue))
}

pub type InsertValue {
  InsertParam(column: String, param: Param)
}

pub fn insert_to_write_query(insert: Insert(a)) -> WriteQuery(a) {
  insert |> InsertQuery
}

fn insert_apply(
  prepared_statement prp_stm: PreparedStatement,
  insert srt: Insert(a),
) {
  let prp_stm =
    prp_stm
    |> prepared_statement.append_sql("INSERT INTO " <> srt.into <> " (")
    |> prepared_statement.append_sql(srt.columns |> string.join(", "))
    |> prepared_statement.append_sql(") VALUES ")

  let prp_stm = case srt.source {
    InsertFromParams(source: src, caster: cstr) ->
      prp_stm |> insert_from_params_apply(source: src, row_caster: cstr)
    InsertFromQuery(query: qry) ->
      prp_stm |> insert_from_query_apply(query: qry)
  }

  prp_stm
}

fn insert_from_params_apply(
  prepared_statement prp_stm: PreparedStatement,
  source src: List(a),
  row_caster cstr: fn(a) -> InsertRow,
) {
  let prp_stm = prp_stm |> prepared_statement.append_sql("(")

  let prp_stm =
    src
    |> list.fold(
      prp_stm,
      fn(new_prp_stm: PreparedStatement, rcrd: a) -> PreparedStatement {
        let InsertRow(row) = rcrd |> cstr

        let apply_row = fn(
          new_prp_stm: PreparedStatement,
          row: List(InsertValue),
        ) -> PreparedStatement {
          row
          |> list.fold(
            new_prp_stm,
            fn(new_prp_stm_inner: PreparedStatement, insert_value: InsertValue) -> PreparedStatement {
              let InsertParam(column: _column, param: param) = insert_value

              case new_prp_stm_inner == new_prp_stm {
                True ->
                  new_prp_stm_inner |> prepared_statement.append_param(param)
                False ->
                  new_prp_stm_inner
                  |> prepared_statement.append_sql(", ")
                  |> prepared_statement.append_param(param)
              }
            },
          )
        }

        case new_prp_stm == prp_stm {
          True -> new_prp_stm |> apply_row(row)
          False ->
            new_prp_stm
            |> prepared_statement.append_sql("), (")
            |> apply_row(row)
        }
      },
    )

  let prp_stm = prp_stm |> prepared_statement.append_sql(")")

  prp_stm
}

fn insert_from_query_apply(
  prepared_statement prp_stm: PreparedStatement,
  query qry: Query,
) {
  prp_stm
  |> prepared_statement.append_sql("(")
  |> query.apply(qry)
  |> prepared_statement.append_sql(")")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Update                                                                   │
// └───────────────────────────────────────────────────────────────────────────┘

// TODO v1
