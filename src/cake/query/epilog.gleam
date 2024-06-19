// TODO v1 module doc
// TODO v1 tests

import cake/internal/query.{type Epilog, Epilog, NoEpilog}

pub fn epilog(epilog eplg: String) -> Epilog {
  case eplg {
    "" -> NoEpilog
    _ -> Epilog(string: eplg)
  }
}
