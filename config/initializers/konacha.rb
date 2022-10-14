if defined?(Konacha)
  formatters = if ENV['KONACHA_REPORTS'] == 'true'
                 require 'rspec/core'
                 require 'rspec/legacy_formatters'
                 require 'ci/reporter/report_manager'
                 require 'ci/reporter/test_suite'
                 require 'ci/reporter/rspec2/formatter'
                 class ::Konacha::CIFormatter < ::CI::Reporter::RSpec2::Formatter
                   def initialize(*args)
                     @report_manager = ::CI::Reporter::ReportManager.new("js")
                     @suite          = nil
                   end
                 end
                 [::Konacha::Formatter.new(STDOUT), ::Konacha::CIFormatter.new(STDOUT)]
               else
                 [::Konacha::Formatter.new(STDOUT)]
               end
  javascipts = %w(chai konacha/iframe jquery jquery_ujs sinon sinon-chai moment spin bootbox user_dashboard/app)
  Konacha.configure do |config|
    config.spec_dir     = "spec/javascripts"
    config.spec_matcher = /_spec\.|_test\./
    config.stylesheets  = %w(application)
    config.javascripts  = javascipts
    config.formatters   = formatters
    require 'capybara/poltergeist'
    config.driver = :poltergeist
    Capybara.server do |app, port|
      require 'rack/handler/thin'
      Rack::Handler::Thin.run(app, Port: port)
    end
  end

  module Konacha
    class SpecsController < ActionController::Base
      rescue_from Konacha::Spec::NotFound do
        render :text => "Not found", :status => 404
      end

      def parent
        @run_mode = params.fetch(:mode, Konacha.mode).to_s.inquiry
        @specs    = Konacha::Spec.all(params[:path])
      end

      def iframe
        @spec        = Konacha::Spec.find_by_name(params[:name])
        @stylesheets = Konacha::Engine.config.konacha.stylesheets
        @javascripts = Konacha::Engine.config.konacha.javascripts
      end

      def user_for_paper_trail
      end
    end
  end

end