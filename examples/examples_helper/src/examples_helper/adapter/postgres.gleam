import cake/adapter/postgres
import gleam/option.{Some}

pub fn with_connection(callback callback) {
  postgres.with_connection(
    host: "localhost",
    port: 5432,
    username: "postgres",
    password: Some("postgres"),
    database: "gleam_cake_examples",
    callback:,
  )
}
