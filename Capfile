# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include the bundler tools
require 'capistrano/bundler'

# Include the rails helpers like deploy:compile_assets
require 'capistrano/rails'

# Include the rvm helpers
require 'capistrano/rvm'

# Include passenger restarting
require 'capistrano/passenger'

# Include dotenv utils such as config:show or config:set VARNAME=value
require 'capistrano/dotenv/tasks'

# Git tag on cap deploy
require 'cap-deploy-tagger/capistrano'

# Post announcement of deploy to slack
# require 'slackistrano/capistrano'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
