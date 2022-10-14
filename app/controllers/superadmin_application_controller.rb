class SuperadminApplicationController < ActionController::Base
  include SSLWithConfiguredPort
  layout 'super_ui'
  before_action :authenticate_super_admin!
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end