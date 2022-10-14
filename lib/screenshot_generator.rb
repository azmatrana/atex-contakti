require 'capybara/poltergeist'
require 'digest'

class ScreenshotGenerator

  def initialize()
    ::Capybara.register_driver :poltergeist do |app|
      ::Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 30, phantomjs_options: ['--ignore-ssl-errors=yes', '--ssl-protocol=any'])
    end
    ::Capybara.app_host = "https://#{::Settings.hostname}"
  end

  def generate_report_screenshot(report, options = {})
    user = report.author
    for_period = options[:start_date] && options[:end_date]
    screenshot_file = for_period ? report.screenshot_for_period(options[:start_date], options[:end_date]) : report.screenshot
    unless screenshot_file.exist? && false
      # using pre-cached file if it exists
      ::FileUtils.mkdir_p ::File.dirname(screenshot_file)
      @session = ::Capybara::Session.new(:poltergeist)
      @session.driver.resize_window(1024, 724)

      report_url = "/reports/#{report.id}/print?email=true&locale=#{options['locale']}"
      report_url += "&start_date=#{options[:start_date].strftime('%Y%m%d')}&end_date=#{options[:end_date].strftime('%Y%m%d')}" if for_period
      report_url += "&token=#{ScreenshotGenerator::secure_token}"
      @session.visit report_url

      sleep 3
      @session.save_screenshot(screenshot_file, full: true)
      generate_pdf(report)
    end
    screenshot_file
  ensure
    # stop phantomjs process
    @session.driver.quit if @session
  end

  def generate_pdf(report)
    if report.summary?
      @session.driver.zoom_factor = 0.75
      @session.driver.paper_size = { format: 'A4', orientation: 'portrait', border: '1cm' }
    else
      @session.driver.paper_size = { format: 'A4', orientation: 'landscape', border: '2cm' }
    end
    @session.save_screenshot(report.pdf, full: true)
  end

  def self.secure_token
    sha256 = Digest::SHA256.new
    sha256.hexdigest Rails.application.secrets.secret_key_base + (Time.new.to_i / 150).to_s
  end

  def self.secure_token_valid?(token)
    sha256 = Digest::SHA256.new
    current = sha256.hexdigest Rails.application.secrets.secret_key_base + (Time.new.to_i / 150).to_s
    previous = sha256.hexdigest Rails.application.secrets.secret_key_base + ((Time.new.to_i / 150) - 1).to_s
    return token == current || token == previous
  end

end
