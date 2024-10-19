# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- ## [Unreleased] -->

## [2.0.1] - 2024-10-19

- Improved Readme

## [2.0.0] - 2024-10-19

- Breaking changes:
  - Renamed `cake.cake_read_query` to `cake.to_read_query`
  - Renamed `cake.cake_write_query` to `cake.to_write_query`
  - Renamed `cake.cake_query_to_prepared_statement` to `cake.to_prepared_statement`

## [1.1.2] - 2024-08-30

- Consistent dialect function names across all 4 RDMBS, fixed/renamed functions:
  - `postgres_dialect/read_cake_query_to_prepared_statement` =>
    `postgres_dialect/cake_query_to_prepared_statement`
  - `postgres_dialect/query_to_prepared_statement` =>
    `postgres_dialect/read_query_to_prepared_statement`
  - `sqlite_dialect/read_cake_query_to_prepared_statement` =>
    `sqlite_dialect/cake_query_to_prepared_statement`
  - `sqlite_dialect/query_to_prepared_statement` =>
    `sqlite_dialect/read_query_to_prepared_statement`
  - Note that while this a breaking change, the compiler will complain and the
    fix is trivial.

## [1.1.1] - 2024-08-09

- Fix gleam min version to 1.3.0 to enable `gleam add cake@1` to work.

## [1.1.0] - 2024-08-09

- Added `join.left_lateral` and `join.inner_lateral` and `join.cross_lateral`
  support `LATERAL JOIN`s available on 🐘PostgreSQL 9.3+ and recent 🐬MySQL versions.
  Notice: You may also use `LATERAL` literally to prefix table names in `FROM`
  clauses with multiple tables.

## [1.0.1] - 2024-07-26

- Breaking but very small bug fix change:
  `insert.on_columns_conflict_ignore` specifies its column list via the
  `columns` label instead of `column` label.

## [1.0.0] - 2024-07-24

- 1.0.0 stable release

## [1.0.0-rc.0] - 2024-07-23

- `insert.on_columns_conflict_update` change the `column` label to `columns`.
- Added `UPDATE` demo.
- Added `INSERT ON CONFLICT UPDATE` demo.
- Added `SELECT` with `JOIN` demo.
- Added a demo using `Fragment` and `PreparedStatement`.
- Added more public utility functions to the `fragment` module.
- Removed glacier dev-dependency to speed up compilation.
- Moved demo apps into sub dir.
- Fixed a few path bugs in docs.

## [0.15.0] - 2024-07-23

In the wake of making this library less verbose and more consistent be aware
about a few slight breaking changes around mostly inserts, updates and deletes.

- Renamed `caster` argument to `encoder` within module `insert`.
- Renamed a lot of public function args to be consistent across the library.
- Added `INSERT` demo.
- Added `DELETE` demo.
- Changed insert param generation to automatically wrap.
- Changed update param functions to automatically wrap. Renamed them slightly.

## [0.14.0] - 2024-07-19

- Added more utility to the `where` module, such as `where.none`, `where.true` and `where.false`.
- Fixed unit tests around `INSERT...ON CONFLICT...UPDATE` with `WHERE` clause.
- Renamed `update.set_many_to_expression` to `update.sets_to_expression` and `update.set_many_to_sub_query` to `update.sets_to_sub_query`.
- Renamed `union_many` to `unions`, `union_all_many` to `unions_all`,
  `except_many` to `excepts`, `except_all_many` to `excepts_all`, and
  `intersect_many` to `intersects`, `intersect_all_many` to `intersects_all`
  in module `combined`.
- Made `where.similar_to` `escape_char` an argument.

## [0.13.0] - 2024-07-12

- Added `where.in_query` which allows to use a sub-query as the right hand side
  of an `IN` clause.
- Added `where.sub_query` which allows to use a sub-query as a `WhereValue`.

## [0.12.0] - 2024-07-12

- Re-export types which can be used in public APIs, this should hopefully
  close the last gaps to never be required to use `cake/internal/*` modules.

  In case you are tempted to do so, please get in touch to see what we can do
  about it.

## [0.11.0] - 2024-07-11

- Renamed `Query` and the internal query module to `ReadQuery` and `read_query`.
- Fixed some issues around upserts (INSERT ON CONFLICT UPDATE).
- Moved internal/params module into public namespace.

## [0.10.1] - 2024-07-10

- Rename dialects such as `postgres` to `postgres_dialect`.
- Fix demos and tests to use public APIs instead of internal ones.

## [0.10.0] - 2024-07-09

- Provide public API to access the generated SQL and prepared statement
  parameters in the base `cake` and new `dialect` modules.

## [0.9.2] - 2024-07-07

- Added more more applications.
- Added tests and snapshots for upserts.

## [0.9.1] - 2024-07-05

- Fix test suite.

## [0.9.0] - 2024-07-05

- Improved documentation.
- Added demo app abstraction.
- Added first runnable demo for `SELECT` and decode.

## [0.8.0] - 2024-07-03

- Flattened the query interface/DSL modules into the base namespace of `cake/`.
- Moved some modules only used internally into `cake/internal/` namespace.
- Fixed and improved test suite for `DELETE` statements.
- Improved general documentation.

## [0.7.0] - 2024-07-01

- Improved builder flexibility for inserts and updates.
- Added documentation for the `insert`, `update` and `delete` interface modules.
- Improved tests for `UPDATE`.
- Renamed `select.groups_by` to `select.group_bys`.
- Fixed bugs when updating with sub-queries, where specifying a sub_query
  while setting update columns to vales would remove all other settings.

## [0.6.0] - 2024-06-27

- Added 🐬MySQL independent of 🦭MariaDB as first class supported.

## [0.5.0] - 2024-06-26

- Fixed github CI and docker compose testing against 🐘PostgreSQL and 🦭MariaDB.
- Locally you should be able to install docker and then just run:
  `bin/docker/detached/` and then `gleam test`.
- Relaxed licence from AGPL 3.0 to Mozilla Public License 2.0 (MPL-2.0).

## [0.4.0] - 2024-06-22

- Added support for deletes and interface modules
  for `insert`, `update`, `delete` ontop of the existing
  `select` and `combined` interface modules.
- Added support for 🦭MariaDB and 🐬MySQL.
- Removed the hard dependency on any RDMBS specific
  library. These are now only required when developing and testing
  this library, but when running you can chose any of the following adapters:
  - `gleam_pgo`
  - `sqlight`
  - `gmysql`

## [0.3.0] - 2024-06-19

- Fixes around inserts, updates, moved a lot of deps to dev deps.

## [0.2.0] - 2024-06-19

- A lot of polishing, support for inserts and updates.

## [0.1.0] - 2024-05-22

- First preview / demo.
