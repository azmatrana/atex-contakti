# Be sure to restart your server when you modify this file.
params = {
  key: '_netdesk_session',
  httponly: true,
  secure: Rails.application.config.try(:use_ssl).is_a?(TrueClass)
}

Netdesk::Application.config.session_store :active_record_store, params
