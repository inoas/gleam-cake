//// 🎂Cake 🪶SQLite adapter which passes `PreparedStatement`s
//// to the `sqlight` library for execution.
////

import cake.{
  type CakeQuery, type PreparedStatement, type ReadQuery, type WriteQuery,
  CakeReadQuery, CakeWriteQuery,
}
import cake/dialect/sqlite_dialect
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import sqlight.{type Connection, type Error, type Value}

/// Connection to a SQLite database.
///
/// This is a thin wrapper around the `sqlight` library's `Connection` type.
///
pub fn with_connection(
  filename filename: String,
  callback callback: fn(Connection) -> a,
) -> a {
  sqlight.with_connection("file:" <> filename, callback)
}

/// Connection to an in-memory SQLite database.
///
/// This is a thin wrapper around the `sqlight` library's `Connection` type.
///
pub fn with_memory_connection(callback callback: fn(Connection) -> a) -> a {
  sqlight.with_connection(":memory:", callback)
}

/// Convert a Cake `ReadQuery` to a `PreparedStatement`.
///
pub fn read_query_to_prepared_statement(
  query query: ReadQuery,
) -> PreparedStatement {
  query |> sqlite_dialect.read_query_to_prepared_statement
}

/// Convert a Cake `WriteQuery` to a `PreparedStatement`.
///
pub fn write_query_to_prepared_statement(
  query query: WriteQuery(t),
) -> PreparedStatement {
  query |> sqlite_dialect.write_query_to_prepared_statement
}

/// Run a Cake `ReadQuery` against an SQLite database.
///
pub fn run_read_query(
  query query: ReadQuery,
  decoder decoder: Decoder(a),
  db_connection db_connection: Connection,
) -> Result(List(a), Error) {
  let prepared_statement = query |> read_query_to_prepared_statement
  let sql_string = prepared_statement |> cake.get_sql
  let db_params =
    prepared_statement
    |> cake.get_params
    |> list.map(with: cake_param_to_client_param)

  sql_string
  |> sqlight.query(on: db_connection, with: db_params, expecting: decoder)
}

/// Run a Cake `WriteQuery` against an SQLite database.
///
pub fn run_write_query(
  query query: WriteQuery(a),
  decoder decoder: Decoder(b),
  db_connection db_connection: Connection,
) -> Result(List(b), Error) {
  let prepared_statement = query |> write_query_to_prepared_statement
  let sql_string = prepared_statement |> cake.get_sql
  let db_params =
    prepared_statement
    |> cake.get_params
    |> list.map(with: cake_param_to_client_param)

  sql_string
  |> sqlight.query(on: db_connection, with: db_params, expecting: decoder)
}

/// Run a Cake `CakeQuery` against an SQLite database.
///
/// This function is a wrapper around `run_read_query` and `run_write_query`.
///
pub fn run_query(
  query query: CakeQuery(a),
  decoder decoder: Decoder(a),
  db_connection db_connection: Connection,
) -> Result(List(a), Error) {
  case query {
    CakeReadQuery(read_query) ->
      read_query |> run_read_query(decoder, db_connection)
    CakeWriteQuery(write_query) ->
      write_query |> run_write_query(decoder, db_connection)
  }
}

/// Execute a raw SQL query against an SQLite database.
///
pub fn execute_raw_sql(
  sql_string sql_string: String,
  db_connection db_connection: Connection,
) -> Result(Nil, Error) {
  sql_string |> sqlight.exec(on: db_connection)
}

fn cake_param_to_client_param(param param: Param) -> Value {
  case param {
    BoolParam(param) -> sqlight.bool(param)
    FloatParam(param) -> sqlight.float(param)
    IntParam(param) -> sqlight.int(param)
    StringParam(param) -> sqlight.text(param)
    NullParam -> sqlight.null()
  }
}
