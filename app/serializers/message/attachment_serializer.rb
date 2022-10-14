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

class Message::AttachmentSerializer < ActiveModel::Serializer
  include ActionView::Helpers::NumberHelper
  attributes :id, :file_name, :file_size, :link, :human_file_size,
             :content_type

  def human_file_size
    number_to_human_size(object.file_size.to_i, precision: 2)
  end
end
