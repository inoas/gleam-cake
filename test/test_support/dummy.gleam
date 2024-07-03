pub fn drop_owners_table_if_exists() {
  "DROP TABLE IF EXISTS owners;"
}

pub fn create_owners_table() {
  "CREATE TABLE owners (
    id INT,
    name TEXT,
    last_name TEXT,
    age INT
  );"
}

pub fn insert_owners_rows() {
  "INSERT INTO owners (id, name, last_name, age) VALUES
    (1, 'Alice', 'Wibble', 5),
    (2, 'Bob', 'Wobble', 8),
    (3, 'Charlie', 'Wabble', 13)
  ;"
}

pub fn drop_cats_table_if_exists() {
  "DROP TABLE IF EXISTS cats;"
}

pub fn create_cats_table() {
  "CREATE TABLE cats (
    name TEXT,
    age INT,
    is_wild BOOLEAN,
    owner_id INT,
    rating FLOAT(8)
  );"
}

pub fn insert_cats_rows() {
  "INSERT INTO cats (name, age, is_wild, owner_id, rating) VALUES
    ('Nubi', 4, TRUE, 1, 2.2),
    ('Biffy', 10, NULL, 2, 1.1),
    ('Ginny', 6, FALSE, 3, NULL),
    ('Karl', 8, TRUE, NULL, 10.0),
    ('Clara', 3, TRUE, NULL, 10.0)
  ;"
}

pub fn drop_dogs_table_if_exists() {
  "DROP TABLE IF EXISTS dogs;"
}

pub fn create_dogs_table() {
  "CREATE TABLE dogs (
    name TEXT,
    age INT,
    is_trained BOOLEAN,
    owner_id INT
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
