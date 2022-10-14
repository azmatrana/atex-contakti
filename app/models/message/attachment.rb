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

class Message::Attachment < ActiveRecord::Base
  acts_as_paranoid
  mount_uploader :file, AttachmentUploader
  skip_callback :commit, :after, :remove_file! # Skip removing on soft delete
  belongs_to :message, class_name: 'Message'
  scope :call_recordings, -> { where(is_call_recording: true) }

  def active_model_serializer
    ::Message::AttachmentSerializer
  end
end
