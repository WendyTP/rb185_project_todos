CREATE TABLE list (
  id serial PRIMARY KEY,
  list_name varchar(100) UNIQUE NOT NULL CHECK(length(list_name) > 0)
);

CREATE TABLE  todo (
  id serial PRIMARY KEY,
  todo_name varchar(100) NOT NULL CHECK(length(todo_name) > 0),
  completed boolean NOT NULL DEFAULT false,
  list_id integer NOT NULL REFERENCES list(id) 
);