# Cake SQL Query Builder for Gleam

Cake is a library written in Gleam to compose SQL queries targeting SQL dialects PostgreSQL, SQLite, MariaDB and MySQL.

[![Package
<a href="https://github.com/inoas/gleam-cake/releases"><img src="https://img.shields.io/github/release/inoas/gleam-cake" alt="GitHub release"></a>
<a href="https://discord.gg/Fm8Pwmy"><img src="https://img.shields.io/discord/768594524158427167?color=blue" alt="Discord chat"></a>
![CI](https://github.com/inoas/gleam-cake/workflows/test/badge.svg?branch=main)
Version](https://img.shields.io/hexpm/v/cake)](https://hex.pm/packages/cake)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cake/)
![Erlang-compatible](https://img.shields.io/badge/target-erlang-b83998)
![JavaScript Compatible](https://img.shields.io/badge/target-javascript-f3e155)
![Unit tests](https://github.com/github/docs/actions/workflows/test.yml/badge.svg)

## Installation

```shell
gleam add cake
```

Further documentation can be found at <https://hexdocs.pm/cake>.

## Examples

See Cake's [tests](https://github.com/inoas/gleam-cake/tree/main/test/cake_test).

## Scope

This is an SQL query building library, thus it is not concerned about:

1. executing queries
2. decoding return values from queries

### Goals

- High degree of flexibility to compose queries:
  While the focus is on building queries up there is also support for replacing
  or removing parts of queries.
- General support on these 4 large RDMS: PostgreSQL, SQLite, MariaDB and MySQL.
- Not being tied to any specific dialect or dialect adapter library.
- Documentation should be extensive and wholesome.
- It should be easy to use with existing gleam dialect adapters such as:
  - `gleam_pgo`
  - `sqlight`
  - `gleam_mysql`

### Non-goals

- You can still craft invalid queries at any time, for example:
  - Omitting certain parts of queries required for them to run, such as
    not specifying a table name
  - Comparing values incompatible by type
- Making sure every possible feature runs on every database.
  For example: While Cake supports `RETURNING` on PostgreSQL and SQLite,
  it does not support it on MariaDB or MySQL.
- Automagic optimization: This library is not here to replace SQL knowledge, but
  to allow crafting and combining SQL queries in a mostly type safe way.

## Tested targets

- Sqlite3 of [ubuntu:latest (Docker)](https://hub.docker.com/_/ubuntu)
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
# or instead of gleam test, run:
# gleam test -- --glacier
# ...for incremental testing
```

### Helper commands

```shell
bin/docker/attached
bin/docker/detached
bin/docker/down

bin/test
bin/glacier

bin/birdie/interactive-review
bin/birdie/accept-all
bin/birdie/reject-all
```

## Library naming

The best part of working with CakePHP 3+ used to be its Query Builder. This library is inspired by that and thus the name.

Thank you [@lorenzo](https://github.com/lorenzo) and [@markstory](https://github.com/markstory) for creating and maintaining CakePHP and its awesome query builder over the years.
