# TODO


- TODO v2 wrap prepared statement in a catch, return Result
- TODO v2 run validator after building, return Result
  - hash the structure, safe hash as valid into cache
  - only run validator if no cache hit
- TODO v2 add all the prepared statement
  - add a client side caching layer
    - safe small results in cache
    - expire cache based on arg, which could also be 0 for no cache

## Examples and/or integration of complex datatypes

- DECIMAL
- DATE
- DATETIME
- DATETIME(6)
- TIME
- TIME(6)
- Timezones

## Query validation

- This could happen on an layer on top where a schema is defined, which would allow auto setting the table but also verifying if certain referenced columns exist. Aliases will make this different though.


## Consider to build libraries on top

Deps to consider:

- act
- aragorn2
- based
- based_pg
- based_sqlite
- bigben
- blah
- carpenter
- cleam
- chrobot browser automation and scaoping
- comet = ">= 0.2.2 and < 2.0.0" # logging
- commonmark
- dot_env
- dotenv_gleam
- envoy
- exception
- fmt
- formal
- glam
- gleam_erlang = ">= 0.25.0 and < 2.0.0"
- gleam_json
- gleamy_structures
- gleamyshell
- glearray
- glemo
- glenvy
- glevenshtein
- gluid
- go_over
- gsv
- hardcache
- html_lustre_converter
- kielet
- libsql
- logging = ">= 1.1.0 and < 2.0.0"
- lustre
- lustre_dev_tools
- lustre_ssg
- migrant
- mist
- mysql-otp maybe, but needs a gleam wrapper first
- nibble
- non_empty_list
- parallel_map
- phony
- prequel
- prng
- ranged_int
- ranger
- rank
- shellout
- spinner
- stacky = ">= 1.4.0 and < 2.0.0"
- storch
- temporary
- tinyroute
- tom
- valid
- wisp
- youid

... and for testing:

- glychee
- qcheck
- qcheck_gleeunit_utils
- testbldr
