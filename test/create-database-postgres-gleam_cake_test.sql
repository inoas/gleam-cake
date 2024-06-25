SELECT 'CREATE DATABASE gleam_cake_test'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'gleam_cake_test'
)
