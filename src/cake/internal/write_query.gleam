//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

import cake/internal/prepared_statement.{
  type DatabaseAdapter, type PreparedStatement,
}
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
    columns: List(String),
    records: List(a),
    caster: fn(a) -> InsertRow,
    // comment: String, // v2
    // with (_recursive?): ?, // v2
    // modifier: String, ? // v1
    // epiloq: Epilog
  )
  // InsertSubQuery(
  //   into: String,
  //   columns: List(String),
  //   records: Query,
  //   caster: fn(a) -> InsertRow,
  // )
}

pub type InsertRow {
  InsertRow(row: List(InsertValue))
}

pub type InsertValue {
  InsertParam(column: String, param: Param)
}

pub fn to_write_query(insert: Insert(a)) -> WriteQuery(a) {
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
  query qry: Insert(a),
) -> PreparedStatement {
  case qry {
    Insert(into: nto, columns: cols, records: rcrds, caster: cstr) ->
      prp_stm
      |> insert_type_apply(
        into: nto,
        columns: cols,
        records: rcrds,
        caster: cstr,
      )
  }
}

fn insert_type_apply(
  prepared_statement prp_stm: PreparedStatement,
  into nto: String,
  columns cols: List(String),
  records rcrds: List(a),
  caster cstr: fn(a) -> InsertRow,
) {
  let prp_stm =
    prp_stm
    |> prepared_statement.append_sql("INSERT INTO " <> nto <> " (")
    |> prepared_statement.append_sql(cols |> string.join(", "))
    |> prepared_statement.append_sql(") VALUES (")

  let prp_stm =
    rcrds
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
