# config valid only for current version of Capistrano
lock '3.5.0'

set :format, :pretty
set :stages, %w(production staging)
set :default_stage, 'staging'

set :application, 'contakti'
set :repo_url, 'git@github.com:EsaLahtinen/contakti.git'

set :branch, ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set(:linked_files, fetch(:linked_files, []).push(
  '.env', 'config/database.yml', 'config/danthes.yml', 'config/danthes_redis.yml', 'config/sidekiq.yml'
  # 'config/schedule.yml',
  )
)
# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads', 'public/chatuploads')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 10

set :passenger_restart_with_touch, true

set :deploy_tag, 'deployed'

#set :slack_webhook, 'https://hooks.slack.com/services/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'
#set :slack_channel, ['#general']
#set :slack_msg_updating, -> {
#  "#{fetch :slack_deploy_user} has started deploying branch #{fetch :branch} of #{fetch :application} to #{fetch :stage, 'an unknown stage'}\n" +
#  "Last 50 commits:\n" +
#  "#{`git log --pretty=oneline --abbrev-commit -n 50`}"
#}

set :ssh_options, {
    forward_agent: true
}

namespace :deploy do
  # after :publishing, 'delete_broken_data'
  after :publishing, 'deploy:restart'
  after :publishing, 'danthes:restart'
  after :publishing, 'sidekiq:restart'
end
