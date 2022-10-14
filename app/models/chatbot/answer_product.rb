class Chatbot::AnswerProduct < ActiveRecord::Base
  belongs_to :answer
  belongs_to :product
end
