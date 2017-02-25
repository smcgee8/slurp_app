require './slurp'
require 'resque/server'

#Secure resque web interface
AUTH_PASSWORD = ENV['RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD']
if AUTH_PASSWORD
  Resque::Server.use Rack::Auth::Basic do |username, password|
    password == AUTH_PASSWORD
  end
end

#Set up Rack
run Rack::URLMap.new \
  "/"       => Sinatra::Application,
  "/resque" => Resque::Server.new
