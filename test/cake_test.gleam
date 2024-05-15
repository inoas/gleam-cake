import birdie
import glacier

// import glacier/should

import pprint

pub fn main() {
  glacier.main()
}

pub fn assert_snap(value v: any, title t: String) -> Nil {
  v |> pprint.format |> birdie.snap(title: t)
}

pub fn assert_snap_tap(value v: any, title t: String) -> any {
  assert_snap(value: v, title: t)
  v
}
