//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

import cake/internal/prepared_statement.{
  type DatabaseAdapter, type PreparedStatement,
}
import cake/internal/query.{type Query}
import cake/param.{type Param}
import gleam/list
import gleam/string

pub type WriteQuery(a) {
  InsertQuery(Insert(a))
  // UpdateQuery(a)
  // DeleteQuery
}

pub type Insert(a) {
  Insert(
    into: String,
    // tag with a?
    columns: List(String),
    source: InsertRecords(a),
    // comment: String, // v2
    // with (_recursive?): ?, // v2
    // modifier: String, ? // v1
    // epiloq: Epilog
  )
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
    InsertFromParams(source: src, caster: cstr) -> prp_stm |> insert_from_params_apply(src, cstr)
    InsertFromQuery(query: qry) -> prp_stm |> insert_from_query_apply(qry)
  }

  prp_stm
}

fn insert_from_params_apply(
  prepared_statement prp_stm: PreparedStatement,
  source src: List(a),
  caster cstr: fn(a) -> InsertRow,
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
