require "pg"

class DatabasePersistance
  def initialize
    @db = PG.connect(dbname: "todos")
  end

  def find_list(id)
    #@session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = @db.exec(sql)
    result.map do |tuple|
      {id: tuple["id"], name: tuple["list_name"], todos: []}
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

end