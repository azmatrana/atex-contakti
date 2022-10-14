# Run with: rackup danthes.ru -E production
require "bundler/setup"
require "yaml"
require "faye"
require "danthes"
require "logger"
require 'dotenv'
load "lib/danthes_extensions.rb"

Dotenv.load ".env.#{ENV['RACK_ENV']}"

Logger.class_eval { alias :write :'<<' }

Danthes.load_config(File.expand_path("../config/danthes.yml", __FILE__))
Faye::WebSocket.load_adapter('puma')

path = File.expand_path("../config/danthes_redis.yml", __FILE__)
if File.exist?(path)
  Danthes.load_redis_config(path)
end

Faye.logger = Logger.new(::File.expand_path('../log/danthes.log', __FILE__))
Faye.logger.level = Logger::DEBUG
use Rack::CommonLogger, Faye.logger

faye_app = Danthes.faye_app

user_subscriptions = UserSubscriptions.new path, ENV['RACK_ENV']

faye_app.add_extension(user_subscriptions)

faye_app.on(:disconnect) do |client_id|
  user_subscriptions.client_disconnected(client_id)
end

run faye_app
