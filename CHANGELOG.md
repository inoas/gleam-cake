# Changelog

## 1.0.0 - 2024-0?-??

- Added more more applications.
- Added tests and snapshots for upserts.

## 0.9.1 - 2024-07-05

- Fix test suite.

## 0.9.0 - 2024-07-05

- Improved documentation.
- Added demo app abstraction.
- Added first runnable demo for `SELECT` and decode.

## 0.8.0 - 2024-07-03

- Flattened the query interface/DSL modules into the base namespace of `cake/`.
- Moved some modules only used internally into `cake/internal/` namespace.
- Fixed and improved test suite for `DELETE` statements.
- Improved general documentation.

## 0.7.0 - 2024-07-01

- Improved builder flexibility for inserts and updates.
- Added documentation for the `insert`, `update` and `delete` interface modules.
- Improved tests for `UPDATE`.
- Renamed `select.groups_by` to `select.group_bys`.
- Fixed bugs when updating with sub-queries, where specifying a sub_query
  while setting update columns to vales would remove all other settings.

## 0.6.0 - 2024-06-27

- Added MySQL independent of MariaDB as first class supported.

## 0.5.0 - 2024-06-26

- Fixed github CI and docker compose testing against Postgres and MariaDB.
- Locally you should be able to install docker and then just run:
  `bin/docker/detached/` and then `gleam test`.
- Relaxed licence from AGPL 3.0 to Mozilla Public License 2.0 (MPL-2.0).

## 0.4.0 - 2024-06-22

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

## 0.3.0 - 2024-06-19

- Fixes around inserts, updates, moved a lot of deps to dev deps.

## 0.2.0 - 2024-06-19

- A lot of polishing, support for inserts and updates.

## 0.1.0 - 2024-05-22

- First preview / demo.
