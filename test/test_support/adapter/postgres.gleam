//// 🎂Cake 🐘PostgreSQL adapter which passes `PreparedStatement`s
//// to the `pog` library for execution.
////

import cake.{
  type CakeQuery, type PreparedStatement, type ReadQuery, type WriteQuery,
  CakeReadQuery, CakeWriteQuery,
}
import cake/dialect/postgres_dialect
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/option.{type Option}
import pog.{type Connection, type QueryError, type Returned, type Value}

/// Connection to a PostgreSQL database.
///
/// This is a thin wrapper around the `pog` library's `Connection` type.
///
pub fn with_connection(
  host host: String,
  port port: Int,
  username username: String,
  password password: Option(String),
  database database: String,
  callback callback: fn(Connection) -> a,
) -> a {
  let connection =
    pog.Config(
      ..pog.default_config(),
      host: host,
      port: port,
      user: username,
      password: password,
      database: database,
    )
    |> pog.connect

  let value = callback(connection)
  pog.disconnect(connection)

  value
}

/// Convert a Cake `ReadQuery` to a `PreparedStatement`.
///
pub fn read_query_to_prepared_statement(
  query query: ReadQuery,
) -> PreparedStatement {
  query |> postgres_dialect.read_query_to_prepared_statement
}

/// Convert a Cake `WriteQuery` to a `PreparedStatement`.
///
pub fn write_query_to_prepared_statement(
  query query: WriteQuery(a),
) -> PreparedStatement {
  query |> postgres_dialect.write_query_to_prepared_statement
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
    |> pog.query
    |> pog_parameters(db_params:)
    |> pog.returning(decoder)
    |> pog.execute(on: on)

  case result {
    Ok(pog.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

/// Run a Cake `WriteQuery` against an PostgreSQL database.
///
pub fn run_write_query(
  query query: WriteQuery(a),
  decoder decoder: Decoder(b),
  db_connection on: Connection,
) -> Result(List(b), QueryError) {
  let prepared_statement = query |> write_query_to_prepared_statement
  let sql_string = prepared_statement |> cake.get_sql
  let db_params =
    prepared_statement
    |> cake.get_params
    |> list.map(with: cake_param_to_client_param)

  let result =
    sql_string
    |> pog.query
    |> pog_parameters(db_params:)
    |> pog.returning(decoder)
    |> pog.execute(on: on)

  case result {
    Ok(pog.Returned(_result_count, v)) -> Ok(v)
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
  |> pog.query
  |> pog.execute(on:)
}

fn cake_param_to_client_param(param param: Param) -> Value {
  case param {
    BoolParam(param) -> pog.bool(param)
    FloatParam(param) -> pog.float(param)
    IntParam(param) -> pog.int(param)
    StringParam(param) -> pog.text(param)
    NullParam -> pog.null()
  }
}

fn pog_parameters(
  pog_query pg_qry: pog.Query(a),
  db_params db_params: List(pog.Value),
) -> pog.Query(a) {
  db_params
  |> list.fold(pg_qry, fn(pg_qry, db_param) {
    pg_qry |> pog.parameter(db_param)
  })
}
