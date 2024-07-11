//// PostgreSQL adapter which which passes `PreparedStatements`
//// to the `gleam_pgo` library for execution.
////

import cake
import cake/internal/dialect.{Postgres}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/read_query.{type ReadQuery}
import cake/internal/write_query.{type WriteQuery}
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/dynamic
import gleam/list
import gleam/option.{Some}
import gleam/pgo.{type Connection, type Value}
import test_support/iox

pub fn read_query_to_prepared_statement(
  query qry: ReadQuery,
) -> PreparedStatement {
  qry |> cake.read_query_to_prepared_statement(dialect: Postgres)
}

pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(a),
) -> PreparedStatement {
  qry |> cake.write_query_to_prepared_statement(dialect: Postgres)
}

pub fn with_connection(f: fn(Connection) -> a) -> a {
  let connection =
    pgo.Config(
      ..pgo.default_config(),
      host: "localhost",
      user: "postgres",
      password: Some("postgres"),
      database: "gleam_cake_test",
    )
    |> pgo.connect

  let value = f(connection)
  pgo.disconnect(connection)

  value
}

pub fn run_read_query(query qry: ReadQuery, decoder dcdr, db_connection db_conn) {
  let prp_stm = read_query_to_prepared_statement(qry)
  let sql = cake.get_sql(prp_stm) |> iox.inspect_println_tap
  let params = cake.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) -> Value {
      case param {
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  let result = sql |> pgo.execute(on: db_conn, with: db_params, expecting: dcdr)

  case result {
    Ok(pgo.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
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
        BoolParam(param) -> pgo.bool(param)
        FloatParam(param) -> pgo.float(param)
        IntParam(param) -> pgo.int(param)
        StringParam(param) -> pgo.text(param)
        NullParam -> pgo.null()
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  let result = sql |> pgo.execute(on: db_conn, with: db_params, expecting: dcdr)

  case result {
    Ok(pgo.Returned(_result_count, v)) -> Ok(v)
    Error(e) -> Error(e)
  }
}

pub fn execute_raw_sql(sql sql: String, connection conn: Connection) {
  sql |> pgo.execute(conn, with: [], expecting: dynamic.dynamic)
}
