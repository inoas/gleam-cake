import gleam/list
import gleam/string

// TODO: Optimize this to be one pass
pub fn map_join(
  list l: List(a),
  map m: fn(a) -> String,
  join j: String,
) -> String {
  l
  |> list.map(m)
  |> string.join(j)
}
