import birdie
import glacier

// import glacier/should

import pprint

pub fn main() {
  glacier.main()
}

pub fn assert_snap(value v: any, title t: String) -> any {
  v |> pprint.format |> birdie.snap(title: t)
  v
}
