ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.default from: ::Settings.from_email
ActionMailer::Base.asset_host = "#{::Settings.protocol}://#{::Settings.hostname}"

ActionMailer::Base.smtp_settings = {
  address: ::Settings.smtp.address,
  port: ::Settings.smtp.port,
  user_name: ::Settings.smtp.user_name,
  password: ::Settings.smtp.password,
  authentication: ::Settings.smtp.authentication,
  enable_starttls_auto: ::Settings.smtp.enable_starttls_auto
}

ActionMailer::Base.default_url_options = {
  host: ::Settings.hostname,
  protocol: ::Settings.protocol
}
