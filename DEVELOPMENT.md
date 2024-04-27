# Development

## TODOs

1. Build an abstraction to create and run arbitrary SQL queries using
   <https://book.cakephp.org/5/en/orm/database-basics.html#running-select-statements>
   as a basis to run against PostgreSQL and Sqlite by utilizing:

   - <https://hexdocs.pm/sqlight/>
   - <https://hexdocs.pm/gleam_pgo/>

   Make certain that RDMBS specific queries can be run through the same abstraction.
   It should be possible as it is still string based.

   - Use snapshot testing soon

2. Build an ActiveRecord pattern
   - Follow CakePHP ORM but put any stateless validation rules in entities (opaque custom types of rows) and put any stateful validation in table types.
