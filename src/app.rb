require 'gopher2000'

set :host, '0.0.0.0'

route '/' do
  render :index
end

menu :index do
  text "index"
end
