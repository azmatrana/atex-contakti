# Dumper (http://dumper.io) is an online tool that provides
# robust database backup in your Rails applications.
#
# For debug logging:
#
# Dumper::Agent.start(app_key: 'YOUR_APP_KEY', debug: true)
#
# For conditional start:
#
# Dumper::Agent.start_if(:app_key => 'YOUR_APP_KEY') do
#   Rails.env.production? && dumper_enabled_host?
# end
#
Dumper::Agent.start_if(app_key: ENV['DUMPER_API_KEY']) do
  ENV['DUMPER_ENABLED'].to_b
end
