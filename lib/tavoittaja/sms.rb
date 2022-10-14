require 'net/https'
require 'uri'

class Tavoittaja::Sms
  API_URI = 'https://api.tavoittaja.fi'

  def initialize(from, to, message)
    @credential = ::Credentials::Tavoittaja.first
    @from = from
    @to = to
    @message = message
  end

  def send
    ::Rails.logger.info("Send sms by Tavoittaja from: #{@from}, to: #{@to}")
    uri = URI.parse(API_URI)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri)
    req.set_form_data({
                        from: @from,
                        to: @to,
                        message: @message,
                        username: @credential.username,
                        password: @credential.password
                      })
    http.request(req)
  end
end
