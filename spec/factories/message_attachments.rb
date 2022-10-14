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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message_attachment, class: 'Message::Attachment' do
    association :message, factory: :message
    file_name 'attachment.txt'
    content_type 'plain/text'
    file_size 12
    file { ::File.open(::Rails.root.join('spec', 'support', 'files', 'attachment.txt')) }
  end
end
