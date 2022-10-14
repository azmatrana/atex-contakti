require 'rails_helper'
require 'turnip/rspec'
require 'turnip/capybara'
# require 'web_puma'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'capybara-screenshot/rspec'

load ::Rails.root.join('spec/support/wait_until.rb')
load ::Rails.root.join('spec/support/delorean.rb')
load ::Rails.root.join('spec/support/webmock.rb')

if (env_no = ENV['TEST_ENV_NUMBER'].to_i).zero?
  Capybara.server_port = 8888
else
  # As described in the readme
  Capybara.server_port = 8888 + env_no
  # Enforces a sleep time, i need to multiply by 10 to achieve consistent results on
  # my 8 cores vm, may work for less though.
  # sleep env_no * 10
end

Capybara.app_host = Capybara.default_host = "http://localhost:#{Capybara.server_port}"

# Use puma as capybara server
#Capybara.server do |app, port|
#  Puma::Server.new(app).tap do |s|
#    s.add_tcp_listener ::Capybara.server_host, port
#  end.run.join
#end

Capybara.always_include_port = true

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
                                    js_errors:         false,
                                    default_wait_time: 30,
                                    timeout:           100,
                                    window_size:       [1280, 1024],
                                    phantomjs_logger: ::File.open(::Rails.root.join('log', 'phantomjs.log').to_s, 'a'),
                                    extensions: ["#{Rails.root}/spec/support/disable_animations.js"]
  )
end

Capybara.register_driver :selenium do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["focusmanager.testmode"] = true
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => profile)
end

# Chrome driver
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Capybara.configure do |config|
  config.javascript_driver      = :poltergeist
  config.default_driver         = :poltergeist
  config.ignore_hidden_elements = false
  config.default_wait_time      = 30
end

Capybara::Screenshot.register_driver(:poltergeist) do |driver, path|
  driver.render(path, full: true)
  driver.save_screenshot(path, full: true)
end

Capybara::Screenshot.screen_shot_and_save_page
Capybara::Screenshot.autosave_on_failure = true

Dir[::Rails.root.join("spec/acceptance/steps/*_steps.rb")].each { |f| load f; true }

RSpec.configure do |config|
  config.include WaitUntil
  config.include FormSteps
  config.include AgentSteps
  config.include ManagerSteps

  config.append_after(:each) do
    Capybara.reset_sessions!
  end

  config.before(:suite) do
    ::Danthes.config[:port] = 9291
    ::Danthes.config[:server] = "http://localhost:9291"
    @danthes_pid_file = ::Process.spawn("bundle exec thin start -R danthes.ru -e test -p 9291 -l #{::Rails.root.join('log', 'thin_danthes.log')}")
  end

  config.before(realtime: true) do
    ::Danthes.config[:port] = 9291
    ::Danthes.config[:server] = "http://localhost:9291"
  end

  config.after(realtime: true) do
    ::Danthes.config[:port] = 9291
    ::Danthes.config[:server] = "http://localhost:9291"
  end

  config.after(:suite) do
    # Kill Danthes
    ::Process.kill('TERM', @danthes_pid_file)
    ::Process.waitpid(@danthes_pid_file)
  end
  config.before(selenium: true) do
    page.driver.browser.manage.window.maximize
  end
end


