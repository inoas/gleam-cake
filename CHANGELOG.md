# Changelog

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
