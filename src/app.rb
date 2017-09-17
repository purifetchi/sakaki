# app.rb - Sakaki Renderer
# (c) 2017 prefetcher

require 'gopher2000'
require 'json'
require 'mysql2'
require 'base64'

# Config loading & host:port setup

config = JSON.parse(File.read('config.json'))
API = "/api/v1"
set :host, config["host_ip"]
set :port, config["port"]

def make_con()
  return Mysql2::Client.new(:host => "localhost", :username => "sakaki", :password => "sakaki", :database => "sakaki")
end

def query(con, stmt, *args)
  return con.prepare(stmt).execute(*args)
end

# Code for Sakaki routing begins here
route '/' do
  render :index
end

route '/about' do
  render :about
end

config["boards"].each do |board, array|
  route '/' + board do
    render :board, make_con(), board
  end

  route '/' + board + '/thread/:id' do
    render :thread, make_con(), board, params[:id]
  end

  route '/' + board + '/reply/:id' do
    con = make_con()
    query(con, "INSERT INTO posts (content, parent, is_op, board) VALUES (?, ?, ?, ?)", request.input, params[:id].to_i, 0, board);
    query(con, "UPDATE posts SET bump_date=CURRENT_TIMESTAMP() WHERE post_id=?", params[:id].to_i);
    render :reply, board, params[:id]
  end

  route '/' + board + '/half' do
    render :half, board, request.input
  end

  route '/' + board + '/post/:title' do
    con = make_con()
    title = Base64.urlsafe_decode64(params[:title])
    query(con, "INSERT INTO posts (title, content, is_op, board) VALUES (?, ?, ?, ?)", title, request.input, 1, board);
    render :post, board
  end
end

# All the renderable menus
menu :index do
  figlet "#{config["name"]}"
  link "About Sakaki", '/about'
  br
  header "Boards"
  config["boards"].each do |board, array|
    menu "/#{board}/ - #{config["boards"][board]["description"]}", "/#{board}"
  end
  br
end

menu :board do |con, board|
  header "/#{board}/"
  br
  input 'Make a new thread', "/#{board}/half"
  br
  query(con, "SELECT * FROM posts WHERE board=? AND is_op=1 ORDER BY bump_date DESC", board).each do |res|
    text "Created on: #{res["date_posted"]}, Latest bump on: #{res["bump_date"]}"
    menu "#{res["title"]}", "/#{board}/thread/#{res["post_id"].to_s}"
    br
  end
  br
end

menu :thread do |con, board, id|
  big_header "thread"
  br
  query(con, "SELECT * FROM posts WHERE parent=? OR post_id=?", id.to_i, id.to_i).each do |res|
    if res["title"] then
      text "#{res["title"]}"
      br
    end

    text "Post number: ##{res["post_id"].to_s}, Posted on: #{res["date_posted"]}"
    text "| #{res["content"]}"
    br
  end
  br
  input 'Reply', "/#{board}/reply/#{id}"
end

menu :reply do |board, id|
  text "Replied to thread #{id}"
  br
  menu 'Go back', "/#{board}/thread/#{id}"
end

menu :half do |board, title|
  big_header "Creating a post with title #{title}"
  br
  encoded = Base64.urlsafe_encode64(title)
  input 'Add OP', "/#{board}/post/#{encoded}"
end

menu :post do |board|
  text "OP posted!"
  br
  menu 'Go back to board', "/#{board}"
end

menu :about do
  "Sakaki is a textboard script for Gopher made in Ruby w/ the Gopher2000 gem.\nSakaki is (c) 2017 prefetcher"
end

# API begins here

route API + '/boards' do
  "#{JSON.dump(config["boards"])}"
end

route API + '/board/:board' do
  payload = []
  query(make_con(), "SELECT * FROM posts WHERE board=? AND is_op=1 ORDER BY bump_date DESC", params[:board]).each do |res|
    output = {:post_id => res["post_id"].to_s, :title => res["title"], :comment => res["content"], :date_posted => res["date_posted"], :date_bumped => res["bump_date"]}
    payload.push(output)
  end
  "#{JSON.dump(payload)}"
end

route API + '/thread/:id' do
  payload = []
  query(make_con(), "SELECT * FROM posts WHERE parent=? OR post_id=?", params[:id].to_i, params[:id].to_i).each do |res|
    output = {:post_id => res["post_id"].to_s, :comment => res["content"], :date_posted => res["date_posted"], :is_op => res["is_op"]}
    if res["is_op"] == 1 then
      output[:title] = res["title"]
      output[:date_bumped] = res["bump_date"]
    end
    payload.push(output)
  end
  "#{JSON.dump(payload)}"
end

# bitch lasagna
