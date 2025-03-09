//// 🎂Cake 🐬MySQL adapter which passes `PreparedStatement`s
//// to the `shork` library for execution.
////

import cake.{
  type CakeQuery, type PreparedStatement, type ReadQuery, type WriteQuery,
  CakeReadQuery, CakeWriteQuery,
}
import cake/dialect/mysql_dialect
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import shork.{type Connection, type QueryError, type Returned, type Value}

/// Connection to a MySQL database.
///
/// This is a thin wrapper around the `shork` library's `Connection` type.
///
pub fn with_connection(callback callback: fn(Connection) -> a) -> a {
  let connection =
    shork.default_config()
    |> shork.host("127.0.0.1")
    |> shork.port(3308)
    |> shork.user("root")
    |> shork.database("gleam_cake_test")
    |> shork.connect

  let value = callback(connection)
  shork.disconnect(connection)

  value
}

/// Convert a Cake `ReadQuery` to a `PreparedStatement`.
///
pub fn read_query_to_prepared_statement(
  query query: ReadQuery,
) -> PreparedStatement {
  query |> mysql_dialect.read_query_to_prepared_statement
}

/// Convert a Cake `WriteQuery` to a `PreparedStatement`.
///
pub fn write_query_to_prepared_statement(
  query query: WriteQuery(a),
) -> PreparedStatement {
  query |> mysql_dialect.write_query_to_prepared_statement
}

pub fn run_read_query(
  query query: ReadQuery,
  decoder decoder: Decoder(a),
  db_connection on: Connection,
) {
  let prepared_statement = query |> read_query_to_prepared_statement
  let sql_string = prepared_statement |> cake.get_sql
  let db_params =
    prepared_statement
    |> cake.get_params
    |> list.map(with: cake_param_to_client_param)

  let result =
    sql_string
    |> shork.query
    |> shork_parameters(db_params:)
    |> shork.returning(decoder)
    |> shork.execute(on:)

  case result {
    Ok(shork.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

/// Run a Cake `WriteQuery` against an PostgreSQL database.
///
pub fn run_write_query(
  query query: WriteQuery(a),
  decoder decoder: Decoder(a),
  db_connection on: Connection,
) -> Result(List(a), QueryError) {
  let prepared_statement = query |> write_query_to_prepared_statement
  let sql_string = prepared_statement |> cake.get_sql
  let db_params =
    prepared_statement
    |> cake.get_params
    |> list.map(with: cake_param_to_client_param)

  let result =
    sql_string
    |> shork.query
    |> shork_parameters(db_params:)
    |> shork.returning(decoder)
    |> shork.execute(on:)

  case result {
    Ok(shork.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

/// Run a Cake `CakeQuery` against an PostgreSQL database.
///
/// This function is a wrapper around `run_read_query` and `run_write_query`.
///
pub fn run_query(
  query query: CakeQuery(a),
  decoder decoder: Decoder(a),
  db_connection db_connection: Connection,
) -> Result(List(a), QueryError) {
  case query {
    CakeReadQuery(read_query) ->
      read_query |> run_read_query(decoder, db_connection)
    CakeWriteQuery(write_query) ->
      write_query |> run_write_query(decoder, db_connection)
  }
}

pub fn execute_raw_sql(
  sql_string sql_string: String,
  db_connection on: Connection,
) -> Result(Returned(Nil), QueryError) {
  sql_string
  |> shork.query
  |> shork.execute(on:)
}

fn cake_param_to_client_param(param param: Param) -> Value {
  case param {
    BoolParam(param) -> shork.bool(param)
    FloatParam(param) -> shork.float(param)
    IntParam(param) -> shork.int(param)
    StringParam(param) -> shork.text(param)
    NullParam -> shork.null()
  }
}

fn shork_parameters(
  shork_query pg_qry: shork.Query(a),
  db_params db_params: List(shork.Value),
) -> shork.Query(a) {
  db_params
  |> list.fold(pg_qry, fn(pg_qry, db_param) {
    pg_qry |> shork.parameter(db_param)
  })
}
