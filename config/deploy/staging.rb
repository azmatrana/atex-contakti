set :rails_env, 'staging'
set :branch, 'staging'
server '78.141.219.212', user: 'admin', roles: %w{app db web sidekiq danthes}

# set :linked_files, ['config/settings/staging.yml']
set :linked_files, []

# namespace :deploy do
#   before :starting, :rewrite_env_file do
#     # rewrite active environment file with corresponding stage file, and git push in deploy branch
#     content_of_original_env = File.read(".env.#{fetch(:rails_env)}")
#     File.open(".env.#{fetch(:rails_env)}", "w") {|file| file.puts File.read(".env.#{fetch(:stage)}") }
#     system "git add -A"
#     system "git commit -m \"deploy to #{fetch(:stage)}\""
#     system "git push origin #{fetch(:branch)}"
#   end

#   # revert changes after deploy and push in deploy branch
#   after :publishing, :revert_env_file do
#     File.open(".env.#{fetch(:rails_env)}", "w") {|file| file.puts content_of_original_env }
#     system "git add -A"
#     system "git commit -m \"after deploy to #{fetch(:stage)}\""
#     system "git push origin #{fetch(:branch)}"
#   end
# end
