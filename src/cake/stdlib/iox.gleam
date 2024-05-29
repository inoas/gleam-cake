import gleam/io
import gleam/string
import pprint

pub fn dbg(v: a) -> a {
  v |> pprint.debug
  v
}

pub fn inspect(v: a) -> String {
  v |> string.inspect
}

pub fn dbg_label(v: a, label: String) -> a {
  #(label, v) |> pprint.debug
  v
}

pub fn print_dashes() -> Nil {
  "─" |> string.repeat(80) |> io.println
}

pub fn print_dashes_tap(v: a) -> a {
  print_dashes()
  v
}

pub fn println(s: String) -> Nil {
  s |> io.println
}

pub fn print(s: String) -> Nil {
  s |> io.print
}

pub fn print_tap(v: a, s: String) -> a {
  s |> io.print
  v
}
