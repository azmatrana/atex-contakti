environment ENV['RAILS_ENV'] || 'production'
daemonize false
quiet
rackup 'danthes.ru'
pidfile 'tmp/pids/danthes.pid'
state_path 'tmp/pids/danthes.state'
stdout_redirect 'log/danthes_access.log', 'log/danthes_error.log', true
preload_app!
workers 1
threads 0, 16
bind "tcp://0.0.0.0:9292"
tag 'danthes'
