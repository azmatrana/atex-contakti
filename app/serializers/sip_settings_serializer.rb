class SipSettingsSerializer < ActiveModel::Serializer
  attributes :title, :user_name, :domain, :password, :ws_server_url
end
