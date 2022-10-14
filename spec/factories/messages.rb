# == Schema Information
#
# Table name: messages
#
#  id             :uuid             not null, primary key
#  number         :integer          default(1), not null
#  from           :string(250)      default(""), not null
#  to             :string(250)      default(""), not null
#  title          :string(250)      default(""), not null
#  description    :text             default(""), not null
#  message_uid    :integer
#  in_reply_to_id :uuid
#  task_id        :integer
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  is_internal    :boolean          default(FALSE), not null
#  sms            :boolean          default(FALSE), not null
#  channel_type   :string(20)       default("email"), not null
#  deleted_at     :datetime
#
# Indexes
#
#  index_messages_on_deleted_at  (deleted_at)
#

FactoryGirl.define do
  factory :message do
    association :task, factory: :task
    number 1
    from { ::FFaker::Internet.email }
    to { ::FFaker::Internet.email }
    title { ::FFaker::Lorem.words(3).join(' ') }
    description { ::FFaker::Lorem.paragraph }
    is_internal false
    channel_type { self.task.media_channel.channel_type }
    factory :message_with_attachment do
      after(:create) do |message, _|
        create(:message_attachment, message: message)
      end
    end
  end
end
