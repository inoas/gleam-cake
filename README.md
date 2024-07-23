# Cake SQL Query Builder for Gleam

Cake is a library written in Gleam to compose SQL queries targeting SQL dialects PostgreSQL, SQLite, MariaDB and MySQL.

<figure>
  <img src="cake-logo.png" alt="Cake Logo" style="max-height: 33vh; width: auto; height: auto" width="480" height="480"/>
  <figcaption><i><small>Cake SQL Query Builder for Gleam</small></i></figcaption>
</figure>


[![Package
<a href="https://github.com/inoas/gleam-cake/releases"><img src="https://img.shields.io/github/release/inoas/gleam-cake" alt="GitHub release"></a>
<a href="https://discord.gg/Fm8Pwmy"><img src="https://img.shields.io/discord/768594524158427167?color=blue" alt="Discord chat"></a>
![CI](https://github.com/inoas/gleam-cake/workflows/test/badge.svg?branch=main)
Version](https://img.shields.io/hexpm/v/cake)](https://hex.pm/packages/cake)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cake/)
![Erlang-compatible](https://img.shields.io/badge/target-erlang-b83998)
![JavaScript Compatible](https://img.shields.io/badge/target-javascript-f3e155)
![test](https://github.com/inoas/gleam-cake/actions/workflows/test.yml/badge.svg?branch=main&event=push)

## Installation

```shell
gleam add cake
```

Further documentation can be found on [hexdocs.pm/cake](https://hexdocs.pm/cake).

## Usage

### Demos

See [docs/demo-apps/README.md](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/README.md#available-demos).

#### Code examples (from the demos)

- [cake\_demo\_select\_and\_decode.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/01_select_and_decode/src/cake_demo_select_and_decode.gleam)
- [cake\_demo\_union\_and\_decode.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/02_union_and_decode/src/cake_demo_union_and_decode.gleam)
- [cake\_demo\_insert.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/03_insert/src/cake_demo_insert.gleam)
- [cake\_demo\_delete.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/04_delete/src/cake_demo_delete.gleam)
- [cake\_demo\_update.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/05_update/src/cake_demo_update.gleam)
- [cake\_demo\_insert\_on\_conflict\_update.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/06_insert_on_conflict_update/src/cake_demo_insert_on_conflict_update.gleam)
- [cake\_demo\_select\_join.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/07_select_join/src/cake_demo_select_join.gleam)
- [cake\_demo\_prepared\_fragment.gleam](https://github.com/inoas/gleam-cake/blob/main/docs/demo-apps/demos/08_prepared_fragment/src/cake_demo_prepared_fragment.gleam)
<!--
- transactions -- TODO v2
- create view -- TODO v3
-->

### Unit tests as examples

See Cake's [tests](https://github.com/inoas/gleam-cake/tree/main/test/cake_test), especially the _Setup_ sections in each test module.

You may also compare the tests with the [snapshots](https://github.com/inoas/gleam-cake/tree/main/birdie_snapshots) results.

### Intended aliases

Use the following aliases to make the library more ergonomic:

```gleam
import cake/select as s // SELECT statements
import cake/where as w // WHERE clauses
import cake/join as j // JOIN clauses
import cake/update as u // UPDATE statements
import cake/insert as i // INSERT statements
import cake/delete as d // DELETE statements
import cake/combined as c // For combined queries such as UNION
import cake/fragment as f // For arbitrary SQL code including functions
```

## Library Design

### Scope

This is an SQL query building library, thus it is not concerned about executing queries or decoding return values from queries, but merely about being a flexible and powerful tool to compose and craft SQL read and write queries.

#### Goals

- High degree of flexibility to compose queries:
  While the focus is on building queries there is also support for replacing
  or removing parts of queries.
- General support on these 4 large RDMS: PostgreSQL, SQLite, MariaDB and MySQL.
- Not being tied to any specific dialect or dialect adapter library.
- Documentation should be comprehensive.
- It should be easy to use with existing gleam dialect adapters such as:
  - [gleam_pgo](https://hex.pm/packages/gleam_pgo)
  - [sqlight](https://hex.pm/packages/sqlight)
  - [gmysql](https://hex.pm/packages/gmysql)
- Allow to define custom SQL fragments while still being safe
  from SQL injections by using prepared statements.

#### Non-goals

- Prohibition of invalid SQL queries: You can still craft invalid queries at
  any time, for example:
  - Omitting certain parts of queries required for them to run, such as
    not specifying a table name
  - Comparing values incompatible by SQL type
- Backporting many features between different RDMBS. For example, while Cake
  supports `RETURNING` on PostgreSQL and SQLite, it does not support it on
  MariaDB or MySQL.
- No automagic optimization: This library is not here to replace SQL knowledge,
  but to allow crafting and combining SQL queries in a flexible and type safe
  way. It might however work as a gateway to obtain SQL knowlege because
  the typed buidler functions help to some degree in understanding how SQL
  queries can be crafted.

### Tested targets

- Sqlite3 as part of [ubuntu:latest (Docker)](https://hub.docker.com/_/ubuntu)
- [postgres:latest (Docker)](https://hub.docker.com/_/postgres)
- [mariadb:latest (Docker)](https://hub.docker.com/_/mariadb)
- [mysql:latest (Docker)](https://hub.docker.com/_/mysql)

The tests run on Erlang but are generally target agnostic:
While the primary use case is to run queries on servers, this library runs on any Gleam target and for example in conjunction with [sqlite3 WASM/JS](https://sqlite.org/wasm) you may run queries composed with this library in browsers.

## Development

### Run test suite locally

```shell
bin/docker/attached
# wait a few seconds until everything is ready
# if you run gleam test too early, it will crash
gleam test
```

### Helper commands

```shell
bin/docker/attached
bin/docker/detached
bin/docker/down

bin/test

bin/birdie/interactive-review
bin/birdie/accept-all
bin/birdie/reject-all
```

## Library naming

The best part of working with CakePHP 3+ used to be its Query Builder. This library is inspired by that and thus the name.

Thank you [@lorenzo](https://github.com/lorenzo) and [@markstory](https://github.com/markstory) for creating and maintaining CakePHP and its awesome query builder over the years.
