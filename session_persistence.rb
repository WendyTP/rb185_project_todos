# Encapsulates all the interaction with session
class SessionPersistance
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find{ |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    list_id = next_element_id(@session[:lists])
    @session[:lists] << { id: list_id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].reject! {|list| list[:id] == id }
  end

  def update_list_name(id, new_name)
    list = find_list(id)
    list[:name] = new_name
  end

  def create_new_todo(list, todo_name)
    todo_id = next_element_id(list[:todos])
    list[:todos] << { id: todo_id, name: todo_name, completed: false }
  end

  def delete_todo_from_list(list, todo_id)
    list[:todos].reject! {|todo| todo[:id] == todo_id}
  end

  def update_todo_status(list, todo_id, new_status)
    todo = list[:todos].find { |t| t[:id] == todo_id}
    todo[:completed] = new_status
  end

  def mark_all_todos_as_completed(list)
    list[:todos].map { |todo| todo[:completed] = true }
  end

  private

  # assign list_id to new todo list or todo_id to new todo item 
  def next_element_id(elements)
    max_existing_element_id = elements.map {|element| element[:id] }.max || 0
    max_existing_element_id + 1
  end
end