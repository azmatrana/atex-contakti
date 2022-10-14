# == Schema Information
#
# Table name: task_notes
#
#  id         :integer          not null, primary key
#  task_id    :integer          not null
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

class Task::Note < ActiveRecord::Base
  belongs_to :task

  validates :task_id, :body, presence: true
  validates :task_id, uniqueness: true
  has_many :attachments, class_name: 'Note::Attachment', dependent: :destroy
end
