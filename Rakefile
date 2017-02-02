require 'bundler/setup'
Bundler.require(:default)
require './slurp'
require 'resque/tasks'
require 'sinatra/activerecord/rake'

task "resque:setup" do
  ENV['QUEUE'] = '*'
end

desc "Alias for resque:work (To run workers on Heroku)"
task "jobs:work" => "resque:work"
