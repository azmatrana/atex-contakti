# == Schema Information
#
# Table name: chat_records
#
#  id                  :integer          not null, primary key
#  channel_id          :string(255)
#  answered_at         :datetime
#  answered_by_user_id :integer
#  service_channel_id  :integer
#  media_channel_id    :integer
#  ended_at            :datetime
#  user_quit           :boolean
#  result              :string(255)
#  name                :string(255)
#  email               :string(255)
#  phone               :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#
# Indexes
#
#  index_chat_records_on_answered_at  (answered_at)
#  index_chat_records_on_channel_id   (channel_id)
#

FactoryGirl.define do
  factory :chat_record do
    channel_id "MyString"
answered_at "2016-04-16 22:40:07"
answered_by 1
chat_ended_at "2016-04-16 22:40:07"
result "MyString"
name "MyString"
email "MyString"
phone "MyString"
  end

end
