# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- TODO

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

- Added MySQL independent of MariaDB as first class supported.

## [0.5.0] - 2024-06-26

- Fixed github CI and docker compose testing against Postgres and MariaDB.
- Locally you should be able to install docker and then just run:
  `bin/docker/detached/` and then `gleam test`.
- Relaxed licence from AGPL 3.0 to Mozilla Public License 2.0 (MPL-2.0).

## [0.4.0] - 2024-06-22

- Added support for deletes and interface modules
  for `insert`, `update`, `delete` ontop of the existing
  `select` and `combined` interface modules.
- Added support for MariaDB and MySQL.
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
