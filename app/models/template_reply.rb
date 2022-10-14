class TemplateReply < ActiveRecord::Base
  belongs_to :company
  validates :text, presence: true, length: { minimum: 2}
end