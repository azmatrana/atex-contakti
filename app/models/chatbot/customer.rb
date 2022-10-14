class Chatbot::Customer < ActiveRecord::Base
  has_one :order, class_name: "Chatbot::Order", foreign_key: 'customer_id'

  validates_presence_of :full_name, :phone_number, :street_address, :zip_code, :city

  VALID_EMAIL_REGEX = /^(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})$/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX, multiline: true}
end
