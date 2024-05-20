import cake/internal/query.{type EpilogPart, Epilog, NoEpilogPart}

pub fn new(epilog eplg: String) -> EpilogPart {
  case eplg {
    "" -> NoEpilogPart
    _ -> Epilog(string: eplg)
  }
}
