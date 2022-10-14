require File.expand_path('../boot', __FILE__)

ENV['RANSACK_FORM_BUILDER'] = '::SimpleForm::FormBuilder'

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
require 'active_record/connection_adapters/postgresql_adapter'
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def set_standard_conforming_strings
    old, self.client_min_messages = client_min_messages, 'warning'
    execute('SET standard_conforming_strings = on', 'SCHEMA') rescue nil
  ensure
    self.client_min_messages = old
  end
end
Bundler.require(*Rails.groups)

module Netdesk
  class Application < Rails::Application
    #config.assets.paths << "#{Rails.root}/app/assets/fonts/glyphicons_regular"

    # don't generate RSpec tests for views and helpers
    config.generators do |g|

      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_girl, dir: 'spec/factories'

      g.view_specs false
      g.helper_specs false
    end

    #ckeditor configuration
    config.assets.precompile += Ckeditor.assets
    config.assets.precompile += %w( ckeditor/* )
    config.autoload_paths    += %W(#{config.root}/app/models/ckeditor)
    CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Helsinki'

    # Autoload all in lib folder
    config.autoload_paths   += %W(#{config.root}/lib)
    config.eager_load_paths += %W(#{config.root}/lib)
    config.autoload_paths   += Dir["#{config.root}/lib/**/"]
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    # Autoload services
    config.autoload_paths   += %W(#{config.root}/services)
    config.eager_load_paths += %W(#{config.root}/services)
    config.autoload_paths   += Dir["#{config.root}/services/**/"]
    config.eager_load_paths += Dir["#{config.root}/services/**/"]
    # Autoload roles
    config.autoload_paths   += %W(#{config.root}/app/roles)
    config.eager_load_paths += %W(#{config.root}/app/roles)
    #if ::Rails.env.production?
    #  config.assets.css_compressor = :yui
    #  config.assets.js_compressor = :yui
    #end

    # to avoid wrapping fields with error in field_with_error div
    config.action_view.field_error_proc = Proc.new do |html_tag, instance|
      html_tag
    end

    config.use_ssl                         = false
    config.assets.initialize_on_precompile = false


    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :options]
      end
    end
  end
end
