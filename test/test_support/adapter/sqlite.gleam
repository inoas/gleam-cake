//// 🪶SQLite adapter which which passes `PreparedStatements`
//// to the `sqlight` library for execution.
////

import cake
import cake/internal/dialect.{Sqlite}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{type ReadQuery}
import cake/internal/write_query.{type WriteQuery}
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/list
import sqlight.{type Connection, type Value}
import test_support/iox

pub fn read_query_to_prepared_statement(
  query qry: ReadQuery,
) -> PreparedStatement {
  qry |> cake.read_query_to_prepared_statement(dialect: Sqlite)
}

pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
) -> PreparedStatement {
  qry |> cake.write_query_to_prepared_statement(dialect: Sqlite)
}

pub fn with_memory_connection(callback_fun: fn(Connection) -> a) -> a {
  sqlight.with_connection(":memory:", callback_fun)
}

pub fn run_read_query(query qry: ReadQuery, decoder dcdr, db_connection db_conn) {
  let prp_stm = read_query_to_prepared_statement(qry)
  let sql = cake.get_sql(prp_stm) |> iox.inspect_println_tap
  let params = cake.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> sqlight.bool(param)
        FloatParam(param) -> sqlight.float(param)
        IntParam(param) -> sqlight.int(param)
        StringParam(param) -> sqlight.text(param)
        NullParam -> sqlight.null()
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  sql |> sqlight.query(on: db_conn, with: db_params, expecting: dcdr)
}

pub fn run_write_query(
  query qry: WriteQuery(a),
  decoder dcdr,
  db_connection db_conn,
) {
  let prp_stm = write_query_to_prepared_statement(qry)
  let sql = cake.get_sql(prp_stm) |> iox.inspect_println_tap
  let params = cake.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> sqlight.bool(param)
        FloatParam(param) -> sqlight.float(param)
        IntParam(param) -> sqlight.int(param)
        StringParam(param) -> sqlight.text(param)
        NullParam -> sqlight.null()
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  sql |> sqlight.query(on: db_conn, with: db_params, expecting: dcdr)
}

pub fn execute_raw_sql(sql sql: String, connection conn: Connection) {
  sql |> sqlight.exec(conn)
}
