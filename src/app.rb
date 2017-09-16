require 'gopher2000'
require 'json'

# Config loading & host:port setup

config = JSON.parse(File.read('config.json'))
set :host, config["host_ip"]
set :port, config["port"]

# Code for Sakaki routing begins here
route '/' do
  render :index
end

config["boards"].each do |board, array|
  route '/' + board do
    render :board
  end
end

# All the renderable menus
menu :index do
  big_header "Sakaki"
  br
  config["boards"].each do |board, array|
    link "/#{board}/ - #{config["boards"][board]["description"]}", "/#{board}"
  end
  br
end

menu :board do
  text "board"
end
