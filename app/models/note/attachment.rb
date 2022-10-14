# == Schema Information
#
# Table name: message_attachments
#
#  id           :integer          not null, primary key
#  message_id   :uuid             not null
#  file         :integer          not null
#  file_name    :string(255)      not null
#  file_size    :integer          not null
#  content_type :string(255)      not null
#  created_at   :datetime
#  updated_at   :datetime
#  deleted_at   :datetime
#
# Indexes
#
#  index_message_attachments_on_deleted_at  (deleted_at)
#

class Note::Attachment < ActiveRecord::Base
  self.table_name = 'note_attachments'
  # acts_as_paranoid
  mount_uploader :file, AttachmentUploader
  skip_callback :commit, :after, :remove_file! # Skip removing on soft delete
  belongs_to :note, class_name: 'Task::Note'

  def active_model_serializer
    ::Note::AttachmentSerializer
  end
end
