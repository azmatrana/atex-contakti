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

require 'spec_helper'

describe Message::Attachment do
  pending "add some examples to (or delete) #{__FILE__}"
end
