import gleam/io

pub fn main() {
  {
    "\n"
    <> "cake is a query building library and cannot be invoked directly."
    <> "\n"
    <> "For demos see cake/internal/examples/"
  }
  |> io.println
}
