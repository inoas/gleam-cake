pub fn drop_owners_table_if_exists() {
  "DROP TABLE IF EXISTS owners;"
}

pub fn create_owners_table() {
  "CREATE TABLE owners (
    id int,
    name text,
    last_name text,
    age int,
    tags text[]
  );"
}

pub fn insert_owners_rows() {
  "INSERT INTO owners (id, name, last_name, age) VALUES
    (1, 'Alice', 'Foo', 5),
    (2, 'bob', 'BOB', 8),
    (3, 'Charlie', 'Quux', 13)
  ;"
}

pub fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

pub fn create_cats_table() {
  "CREATE TABLE cats (
    name text,
    age int,
    is_wild boolean,
    owner_id int
  );"
}

pub fn insert_cats_rows() {
  "INSERT INTO cats (name, age, is_wild, owner_id) VALUES
    ('Nubi', 4, TRUE, 1),
    ('Biffy', 10, NULL, 2),
    ('Ginny', 6, FALSE, 3),
    ('Karl', 8, TRUE, NULL),
    ('Clara', 3, TRUE, NULL)
  ;"
}

pub fn drop_dogs_table_if_exists() {
  "DROP TABLE IF EXISTS dogs;"
}

pub fn create_dogs_table() {
  "CREATE TABLE dogs (
    name text,
    age int,
    is_trained boolean,
    owner_id int
  );"
}

pub fn insert_dogs_rows() {
  "INSERT INTO dogs (name, age, is_trained, owner_id) VALUES
    ('Fubi', 1, TRUE, 1),
    ('Diffy', 2, NULL, 2),
    ('Tinny', 3, FALSE, 3),
    ('Karl', 4, TRUE, NULL),
    ('Clara', 5, TRUE, NULL)
  ;"
}
