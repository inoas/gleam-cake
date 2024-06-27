//// MariaDB/MySQL adapter which which passes `PreparedStatements`
//// to the `gmysql` library for execution.
////

import cake/dialect.{Maria}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/query.{type Query}
import cake/internal/write_query.{type WriteQuery}
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/list
import gleam/option.{None, Some}
import gmysql.{type Connection}
import test_support/iox

const placeholder_base = "?"

pub fn to_prepared_statement(query qry: Query) -> PreparedStatement {
  qry
  |> query.to_prepared_statement(plchldr_bs: placeholder_base, dialect: Maria)
}

pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(t),
) -> PreparedStatement {
  qry
  |> write_query.to_prepared_statement(
    plchldr_bs: placeholder_base,
    dialect: Maria,
  )
}

pub fn with_connection(f: fn(Connection) -> a) -> a {
  let assert Ok(connection) =
    gmysql.Config(
      host: "localhost",
      user: Some("root"),
      password: None,
      database: "gleam_cake_test",
      port: 3306,
      connection_mode: gmysql.Synchronous,
      connection_timeout: gmysql.Infinity,
      keep_alive: 999_999_999,
    )
    |> gmysql.connect

  let value = f(connection)
  gmysql.disconnect(connection)

  value
}

pub fn run_query(query qry: Query, decoder dcdr, db_connection db_conn) {
  let prp_stm = to_prepared_statement(qry)
  let sql = prepared_statement.get_sql(prp_stm) |> iox.inspect_println_tap
  let params = prepared_statement.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) {
      case param {
        BoolParam(param) ->
          case param {
            True -> gmysql.to_param(1)
            False -> gmysql.to_param(0)
          }
        FloatParam(param) -> gmysql.to_param(param)
        IntParam(param) -> gmysql.to_param(param)
        StringParam(param) -> gmysql.to_param(param)
        NullParam -> gmysql.to_param(Nil)
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  sql |> gmysql.query(on: db_conn, with: db_params, expecting: dcdr)
}

pub fn run_write(query qry: WriteQuery(t), decoder dcdr, db_connection db_conn) {
  let prp_stm = write_query_to_prepared_statement(qry)
  let sql = prepared_statement.get_sql(prp_stm) |> iox.inspect_println_tap

  let params = prepared_statement.get_params(prp_stm)

  let db_params =
    params
    |> list.map(fn(param: Param) {
      case param {
        // TODO: If all we need is this, "use based" library?
        BoolParam(param) -> gmysql.to_param(param)
        FloatParam(param) -> gmysql.to_param(param)
        IntParam(param) -> gmysql.to_param(param)
        StringParam(param) -> gmysql.to_param(param)
        NullParam -> gmysql.to_param(Nil)
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  sql |> gmysql.query(on: db_conn, with: db_params, expecting: dcdr)
}

pub fn execute_raw_sql(sql sql: String, connection cnn: Connection) {
  sql |> gmysql.exec(on: cnn)
}
