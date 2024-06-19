//// MariaDB/MySQL adapter which which passes `PreparedStatements`
//// to the `sqlight` library for execution.
////

import cake/dialect.{Maria}
import cake/internal/prepared_statement.{type PreparedStatement}
import cake/internal/query.{type Query}
import cake/internal/stdlib/iox
import cake/internal/write_query.{type WriteQuery}
import cake/param.{
  type Param, BoolParam, FloatParam, IntParam, NullParam, StringParam,
}
import gleam/list
import gleam/option.{Some}
import gmysql.{type Connection}

const placeholder_prefix = "?"

pub fn to_prepared_statement(query qry: Query) -> PreparedStatement {
  qry
  |> query.to_prepared_statement(
    placeholder_prefix: placeholder_prefix,
    dialect: Maria,
  )
}

pub fn write_query_to_prepared_statement(
  query qry: WriteQuery(t),
) -> PreparedStatement {
  qry
  |> write_query.to_prepared_statement(
    placeholder_prefix: placeholder_prefix,
    dialect: Maria,
  )
}

pub fn with_connection(f: fn(Connection) -> a) -> a {
  let assert Ok(connection) =
    gmysql.connect(gmysql.Config(
      host: "127.0.0.1",
      user: Some("root"),
      password: Some("secret"),
      database: "cake_gleam",
      port: 3306,
      connection_mode: gmysql.Synchronous,
      connection_timeout: 90,
      keep_alive: 30,
    ))

  let value = f(connection)
  gmysql.close(connection)

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
        BoolParam(param) -> gmysql.to_param(param)
        FloatParam(param) -> gmysql.to_param(param)
        IntParam(param) -> gmysql.to_param(param)
        StringParam(param) -> gmysql.to_param(param)
        NullParam -> gmysql.to_param(Nil)
      }
    })
    |> iox.print_tap("Params: ")
    |> iox.inspect_println_tap

  gmysql.query(db_conn, sql, db_params, 0, dcdr)
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

  gmysql.query(db_conn, sql, db_params, 999_999, dcdr)
}

pub fn execute_raw_sql(query qry: String, connection conn: Connection) {
  gmysql.exec(conn, qry, 999_999)
}
