import cake/internal/query.{type Epilog, Epilog, NoEpilog}

pub fn new(epilog eplg: String) -> Epilog {
  case eplg {
    "" -> NoEpilog
    _ -> Epilog(string: eplg)
  }
}
