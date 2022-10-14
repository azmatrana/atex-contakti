# == Schema Information
#
# Table name: chat_settings
#
#  id                   :integer          not null, primary key
#  whitelisted_referers :text
#  created_at           :datetime
#  updated_at           :datetime
#  color                :string(255)      default("#0dc0c0")
#  welcome_message      :string(255)      default("How can I help?")
#  initial_msg          :string(255)      default("")

class ChatSettings < ActiveRecord::Base
  enum format: [:classic, :inquiry]
  mount_uploader :file, ChatLogoUploader
  has_many :media_channels
  has_many :chat_inquiry_fields
  has_many :chat_initial_buttons
  after_create :create_chat_inquiry_fields

  accepts_nested_attributes_for :chat_inquiry_fields, allow_destroy: true
  accepts_nested_attributes_for :chat_initial_buttons, allow_destroy: true

  def create_chat_inquiry_fields
    titles = ["Name", "Email", "Phone"]
    titles.each do |title|
      self.chat_inquiry_fields.create(title: title)
    end
  end



end
