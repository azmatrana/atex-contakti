class Kimai::KimaiDetail < ActiveRecord::Base
  belongs_to :user

  validate :validate_credentials, if: Proc.new { |a| a.tracker_email.present? & a.tracker_auth_token.present? }


  def validate_credentials
    begin
      validate_from_api
    rescue => error
      errors.add :base, error.message
      return false
    end
    true
  end


  def validate_from_api
    company = self.user.company
    url = company.kimai_tracker_api_url
    if url.blank?
      raise "Time tracker is not being setup. Please contact administrator." 
    end

    uri = URI.parse("#{url}/api/users/me")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri, {'Content-Type' => 'application/json'})

    request.add_field("X-AUTH-USER", self.tracker_email)
    request.add_field("X-AUTH-TOKEN", self.tracker_auth_token)

    response = http.request(request)

    if (response.code != "200")
      body = JSON.parse(response.body) 
      raise body["message"]
    end
  end
end
