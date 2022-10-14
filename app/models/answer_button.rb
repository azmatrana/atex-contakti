class AnswerButton < ActiveRecord::Base
  belongs_to :answer
  validates_presence_of :text
end
