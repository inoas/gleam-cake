//// Allows appending aribtrary text to the end of the generated
//// SQL query. This is useful for adding adapter specific
//// modifiers such as `FOR UPDATE`, for example, see
//// <https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-TABLES>
////

import cake/internal/query.{type Epilog, Epilog, NoEpilog}

pub fn epilog(epilog eplg: String) -> Epilog {
  case eplg {
    "" -> NoEpilog
    _ -> Epilog(string: eplg)
  }
}

pub fn no_epilog() -> Epilog {
  NoEpilog
}
