import gleam/list

pub fn append_item(list l: List(a), item i: a) -> List(a) {
  l |> list.append([i])
}
