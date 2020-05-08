require "pg"

class DatabasePersistance
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)
    tuple = result.first
    list_id = tuple["id"].to_i
    {id: list_id, name: tuple["list_name"], todos: find_todos(list_id)}
    # todos: [{ id: todo_id, name: todo_name, completed: false }]
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
      list_id = tuple["id"].to_i
      {id: list_id, name: tuple["list_name"], todos: find_todos(list_id)}
    end
  end

  def create_new_list(list_name)
    #list_id = next_element_id(@session[:lists])
    #@session[:lists] << { id: list_id, name: list_name, todos: [] }
  end

  def delete_list(id)
    #@session[:lists].reject! {|list| list[:id] == id }
  end

  def update_list_name(id, new_name)
    #list = find_list(id)
    #list[:name] = new_name
  end

  def create_new_todo(list, todo_name)
    #todo_id = next_element_id(list[:todos])
    #list[:todos] << { id: todo_id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list, todo_id)
    #list[:todos].reject! {|todo| todo[:id] == todo_id}
  end

  def update_todo_status(list, todo_id, new_status)
    #todo = list[:todos].find { |t| t[:id] == todo_id}
    #todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list)
    #list[:todos].map { |todo| todo[:completed] = true }
  end

  private

  def find_todos(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1;"
    result = query(sql, list_id)
    todos = result.map do |tuple|
      todo_id = tuple["id"].to_i
      complete_status = (tuple["completed"] == "t") ? true : false
      {id: todo_id, name: tuple["todo_name"], completed: complete_status }
    end
  end
end