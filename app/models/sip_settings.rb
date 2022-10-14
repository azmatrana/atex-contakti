class SipSettings < ActiveRecord::Base
  has_one :media_channel
  has_one :agent, class_name: "User"
  has_one :sip_widget
  belongs_to :company

  validates :user_name, :password, :domain, :ws_server_url, presence: true

  accepts_nested_attributes_for :sip_widget

end
