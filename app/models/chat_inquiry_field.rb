class ChatInquiryField < ActiveRecord::Base
  belongs_to :chat_settings
  validates_associated :chat_settings
  default_scope { order(id: :desc) }
end