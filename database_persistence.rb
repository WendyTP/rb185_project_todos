require "pg"

# To interact with database values
class DatabasePersistance
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<~SQL
      SELECT lists.*, 
        count(todos.id) AS todos_total_count,
        count(NULLIF(todos.completed, true))AS todos_remaining_count 
        FROM lists 
        LEFT JOIN todos ON (lists.id = todos.list_id)
        WHERE lists.id = $1
        GROUP BY  lists.id 
        ORDER BY lists.list_name;
    SQL
    result = query(sql, id)
    tuple = result.first
    list_id = tuple["id"].to_i  # --- needed?

    { id: list_id, 
      name: tuple["list_name"], 
      todos: find_todos(list_id),
      todos_total_count: 0,
      todos_remaining_count: 0}
  end

  def all_lists
    sql = <<~SQL
      SELECT lists.*, 
        count(todos.id) AS todos_total_count,
        count(NULLIF(todos.completed, true))AS todos_remaining_count 
        FROM lists 
        LEFT JOIN todos ON (lists.id = todos.list_id)
        GROUP BY  lists.id 
        ORDER BY lists.list_name;
    SQL
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"].to_i, 
        name: tuple["list_name"], 
        todos_total_count: tuple["todos_total_count"].to_i, 
        todos_remaining_count: tuple["todos_remaining_count"].to_i 
      }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (list_name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    sql_for_delete_todos = "DELETE FROM todos WHERE list_id = $1"
    result_for_delete_todos = query(sql_for_delete_todos, id)
    sql_for_delete_list = "DELETE FROM lists WHERE id = $1;"
    result_for_delete_list = query(sql_for_delete_list, id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET list_name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (todo_name, list_id) VALUES ($1, $2);"
    query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, new_status, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end

  private

  def find_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1;"
    result = query(sql, list_id)
    todos = result.map do |tuple|
      todo_id = tuple["id"].to_i
      complete_status = (tuple["completed"] == "t") ? true : false
      { id: todo_id, name: tuple["todo_name"], completed: complete_status }
    end
  end
end
