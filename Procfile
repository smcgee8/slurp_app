web: bundle exec rackup config.ru -p $PORT
resque-web: resque-web --foreground
worker: bundle exec rake jobs:work
