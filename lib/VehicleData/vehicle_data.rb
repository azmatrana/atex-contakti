require 'json'
require 'logger'
require 'net/http'

class VehicleData
  VEHICLES_API_HOST = "https://mycar.probissolutions.fi"

  class RequestError < StandardError;
    attr_reader :message, :code

    def initialize(message, code='no_code')
      @message = message
      @code = code
    end

  end

  def initialize(opts = {})
    @access_token = opts[:access_token]
    @reg_num = opts[:registration_number]
    if opts[:logger]
      @logger = opts[:logger]
    end
  end

   def logger
    @logger ||= begin
      x = Logger.new(STDOUT)
      x.level = Logger::INFO
      x
    end
  end

  def fetch_vehicle_info(options = {})
    res = req(logger, @access_token, Net::HTTP::Get, "/api/contakti/vehicles/search/#{@reg_num}", {})
    return res
  end

  def req(logger, access_token, method_class, path, params = {}, payload = {})
    uri = URI(VEHICLES_API_HOST + path)
    uri.query = URI.encode_www_form(params)

    logger.debug("#{method_class} #{uri}")

    request = method_class.new(uri)
    request['api-key'] = access_token
    request['accept'] = 'application/json'
    request.add_field 'Content-Type', 'application/json'
    request.body = payload.to_json

    Net::HTTP.start(uri.host, uri.port, { :use_ssl => uri.scheme == 'https' }) do |http|
      rsp = http.request(request)
      json = JSON.parse(rsp.body)
      if rsp.code.to_i != 200
        if (json.is_a?(Hash) and json.has_key?('error'))
          return RequestError.new(" VEHICLES API responded with an error: #{json['error']}", json['code'])
        else
          return RequestError.new("VEHICLES API responded with an error: #{json}")
        end
        error_msg = (json.is_a?(Hash) and json.has_key?('error')) ? json['error'] : json
      end
      logger.debug("#{method_class} #{uri} #{json}")
      json
    end
  end
end
