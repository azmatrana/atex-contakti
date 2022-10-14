class Chatbot::Stat < ActiveRecord::Base

  include TimeScopes
  
  belongs_to :company
  belongs_to :service_channel
end
