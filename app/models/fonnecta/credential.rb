# == Schema Information
#
# Table name: fonnecta_credentials
#
#  id              :integer          not null, primary key
#  client_id       :string(255)      not null
#  client_secret   :string(255)      not null
#  token           :string(255)
#  token_taken_at  :datetime
#  token_expire_in :integer
#  created_at      :datetime
#  updated_at      :datetime
#

require 'net/https'
require 'uri'

class Fonnecta::Credential < ActiveRecord::Base
  self.table_name = 'fonnecta_credentials'

  validates :client_id, :client_secret, presence: true

  before_save :check_credentials_changings

  def check_credentials_changings
    if client_id_changed? || client_secret_changed?
      self.token           = nil
      self.token_taken_at  = nil
      self.token_expire_in = nil
    end
  end

  def update_token(token, expire_in)
    self.token           = token
    self.token_taken_at  = ::Time.current
    self.token_expire_in = expire_in.to_i
  end

  def token_usable?
    return false unless self.token.present?
    self.token_taken_at + token_expire_in.seconds - 1.minute > ::Time.current
  end

  def get_new_token
    response = make_login_request
    result   = ::JSON.parse(response.body)
    update_token(result['access_token'], result['expires_in'])
  end

  def get_new_token!
    get_new_token
    save!
  end

  def make_login_request
    uri          = URI.parse('https://auth.fonapi.fi/token/login')
    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req          = Net::HTTP::Post.new(uri.request_uri)
    req.set_form_data({
                        grant_type:    'client_credentials',
                        client_id:     client_id,
                        client_secret: client_secret
                      })
    http.request(req)
  end

end
