//// Contains types and composition functions to build
//// _write queries_, such as `INSERT`, `UPDATE` and `DELETE`.
////

import cake/internal/prepared_statement.{
  type DatabaseAdapter, type PreparedStatement,
}
import cake/param.{type Param}
import gleam/list
import gleam/string

pub type Write(a) {
  InsertQuery(Insert(a))
  // UpdateQuery(a)
  // DeleteQuery
}

pub type Insert(a) {
  InsertType(
    into: String,
    records: List(a),
    cols: fn(a) -> List(String),
    caster: fn(a) -> InsertRow,
    // comment: String, // v2
    // with (_recursive?): ?, // v2
    // modifier: String, ? // v1
    // epiloq: Epilog
  )
  // InsertDynamic(
  //   into: String,
  //   values: List(Dict(String, Dynamic)),
  // )
  // InsertSubQuery(
  //   into: String,
  //   values: Query,
  //   alias: String,
  // )
}

pub type InsertRow {
  InsertRow(row: List(InsertPair))
}

pub type InsertPair {
  InsertPair(pair: #(String, Param))
}

pub fn insert_to_write(insert: Insert(a)) -> Write(a) {
  insert |> InsertQuery
}

pub fn to_prepared_statement(
  query qry: Write(a),
  placeholder_prefix prp_stm_prfx: String,
  database_adapter db_adptr: DatabaseAdapter,
) -> PreparedStatement {
  prp_stm_prfx
  |> prepared_statement.new(db_adptr)
  |> apply(qry)
}

fn apply(
  prepared_statement prp_stm: PreparedStatement,
  query qry: Write(a),
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
    InsertType(into: nto, cols: cls, records: rcrds, caster: cstr) ->
      prp_stm
      |> insert_type_apply(into: nto, cols: cls, records: rcrds, caster: cstr)
  }
}

fn insert_type_apply(
  prepared_statement prp_stm: PreparedStatement,
  into nto: String,
  cols cls: fn(a) -> List(String),
  records rcrds: List(a),
  caster cstr: fn(a) -> InsertRow,
) {
  let assert [rcrd, ..] = rcrds

  let prp_stm =
    prp_stm
    |> prepared_statement.append_sql("INSERT INTO " <> nto <> " (")
    |> prepared_statement.append_sql(rcrd |> cls |> string.join(", "))
    |> prepared_statement.append_sql(") VALUES (")

  let prp_stm =
    rcrds
    |> list.fold(
      prp_stm,
      fn(new_prp_stm: PreparedStatement, rcrd: a) -> PreparedStatement {
        // Need to make sure it aint empty outside
        let InsertRow(row) = rcrd |> cstr

        let apply_row = fn(
          new_prp_stm: PreparedStatement,
          row: List(InsertPair),
        ) -> PreparedStatement {
          row
          |> list.fold(
            new_prp_stm,
            fn(new_prp_stm_inner: PreparedStatement, pair: InsertPair) -> PreparedStatement {
              let InsertPair(pair: pair) = pair
              let #(_col, val) = pair

              case new_prp_stm_inner == new_prp_stm {
                True ->
                  new_prp_stm_inner |> prepared_statement.append_param(val)
                False ->
                  new_prp_stm_inner
                  |> prepared_statement.append_sql(", ")
                  |> prepared_statement.append_param(val)
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

pub type Wibble {
  Wibble(name: String, age: Int, is_wild: Bool)
}

fn wibble_cols(wibble: a) -> List(String) {
  ["name", "age", "is_wild"]
}

fn wibble_caster(wibble: a) -> InsertRow {
  let Wibble(name: name, age: age, is_wild: is_true) = wibble

  InsertRow(row: [
    InsertPair(pair: #("name", param.string("Wibble"))),
    InsertPair(pair: #("age", param.int(42))),
    InsertPair(pair: #("is_wild", param.bool(True))),
  ])
}

pub fn wibble_write() -> Write(Wibble) {
  [Wibble(name: "Wibble", age: 42, is_wild: True)]
  |> InsertType(into: "cats", cols: wibble_cols, caster: wibble_caster)
  |> insert_to_write
}
