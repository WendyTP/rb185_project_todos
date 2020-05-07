require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @storage = SessionPersistance.new(session)
end

helpers do
  def list_completed?(list)
    todos_total_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_completed?(list)
  end

  def todos_remaining_count(list)
    result = 0
    list[:todos].each do |todo|
      result += 1 if todo[:completed] == false
    end
    result
  end

  def todos_total_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| block.call(list) }
    complete_lists.each { |list| block.call(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| block.call(todo) }
    complete_todos.each { |todo| block.call(todo) }
  end
end

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
    list_id = next_list_id(@session[:lists])
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
    todo_id = next_todo_id(list[:todos])
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

  # assign list_id to new todo list  # ----- combine next_list_id with next_todo_id?
  def next_list_id(lists)
    max_existing_list_id = lists.map {|list| list[:id] }.max || 0
    max_existing_list_id + 1
  end

  # assign todo_id to new todo item
  def next_todo_id(todos)
    max_existing_todo_id = todos.map {|todo| todo[:id]}.max || 0
    max_existing_todo_id + 1
  end
end

def load_list(id)
  list = @storage.find_list(id)
    return list if list

    session[:error] = "The specified list was not found."
    redirect "/lists"
end

# Return an error message if the list name is invalid.
# Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name].downcase == name.downcase }
    "List name must be unqiue."
  end
end

# Return an error message if the todoname is invalid.
# Return nil if name is valid.
def error_for_todo_name(name, list)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters."
  elsif list[:todos].any? { |todo| todo[:name].downcase == name.downcase }
    "Todo name must be unqiue."
  end
end




get "/" do
  redirect "/lists"
end

# View all the lists (list of lists)
get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
   
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single list
get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  erb :list, layout: :layout
end

# Render an edit-list form for an exisiting todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Update an exisitng todo list (the name of list)
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id) # ------------------------------needed?

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i
  @storage.delete_list(id)
  session[:success] = "The list has been deleted"
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else   
    redirect "/lists"
  end
end

# Add a todo item to a todo list
post "/lists/:list_id/todos" do
  text = params[:todo].strip
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  error = error_for_todo_name(text, @list)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list, text)
    
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo item
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i

  @storage.delete_todo_from_list(@list, todo_id)
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been updated"
    redirect "/lists/#{@list_id}"
  end
end

# Update the status of a todo item
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"

  @storage.update_todo_status(@list, todo_id, is_completed)
 
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# Mark all todos on a todo list as complete
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  @storage.mark_all_todos_as_completed(@list)

  session[:success] = "All todos have been completed."
  redirect "lists/#{@list_id}"
end
