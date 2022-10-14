class AnswerCompanyFile < ActiveRecord::Base
  belongs_to :answer
  belongs_to :company_file
end
