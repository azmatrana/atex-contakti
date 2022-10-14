require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq/middleware/i18n'
require 'sidekiq-status'

if Rails.env.production? || Rails.env.staging?
  if ENV['SIDEKIQ_USER'] && ENV['SIDEKIQ_PASSWORD']
    ::Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      [user, password] == [ENV['SIDEKIQ_USER'], ENV['SIDEKIQ_PASSWORD']]
    end
  end
end

::Sidekiq.configure_server do |config|
  config.redis = { :namespace => ENV['SIDEKIQ_NAMESPACE'] || 'netdesk' }
  unless ::Rails.env.test?
    require 'sidekiq-cron'
    schedule_file = ::Rails.root.join('config', 'schedule.yml').to_s
    Rails.logger = Sidekiq::Logging.logger
    ActiveRecord::Base.logger = Sidekiq::Logging.logger
    # Cleanup all cron jobs
    Sidekiq::Cron::Job.destroy_all!
    if File.exist?(schedule_file)
      ::Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    end
  end
end

::Sidekiq.configure_client do |config|
  config.redis = { :namespace => ENV['SIDEKIQ_NAMESPACE'] || 'netdesk' }
end

