module SSLWithConfiguredPort
  extend ActiveSupport::Concern

  included do
    force_ssl_with_configured_port if: :use_ssl?
  end

  private
  # This will return true if the config has *config.use_ssl = true*
  def use_ssl?
    Rails.application.config.try(:use_ssl).is_a?(TrueClass)
  end

  module ClassMethods
    def force_ssl_with_configured_port(options = {})
      options[:port] = Rails.application.config.ssl_port if options[:port].blank? && Rails.application.config.try(:ssl_port).present?
      force_ssl options
    end
  end
end