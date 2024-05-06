import gleam/io
import gleam/string
import pprint

pub fn dbg(v) {
  pprint.debug(v)
  v
}

pub fn inspect(v) {
  string.inspect(v)
}

pub fn dbg_label(v, label: String) {
  pprint.debug(#(label, v))
  v
}

pub fn print_dashes() {
  string.repeat("─", 80) |> io.println()
}

pub fn print_dashes_tap(v) {
  print_dashes()
  v
}

pub fn println(s: String) {
  io.println(s)
}

pub fn print(s: String) {
  io.print(s)
}
