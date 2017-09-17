# app.rb - Sakaki Renderer
# (c) 2017 prefetcher

require 'gopher2000'
require 'json'
require 'mysql2'

# Config loading & host:port setup

config = JSON.parse(File.read('config.json'))
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

config["boards"].each do |board, array|
  route '/' + board do
    render :board, make_con(), board
  end
end

# All the renderable menus
menu :index do
  big_header "Sakaki"
  br
  config["boards"].each do |board, array|
    menu "/#{board}/ - #{config["boards"][board]["description"]}", "/#{board}"
  end
  br
end

menu :board do |con, board|
  big_header "/#{board}/"
  br
  query(con, "SELECT * FROM posts WHERE board='#{board}' AND is_op=1 ORDER BY bump_date DESC") do |res|
    menu "=#{res["title"]}= [Created on: #{res["date_posted"]}, Latest bump on: #{res["bump_date"]}]", "/#{board}/thread/#{res["post_id"].to_s}"
  end
  br
end
