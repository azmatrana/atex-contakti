# == Schema Information
#
# Table name: tasks
#
#  id                  :integer          not null, primary key
#  state               :string(100)      default(""), not null
#  service_channel_id  :integer
#  created_at          :datetime
#  updated_at          :datetime
#  uuid                :uuid
#  minutes_spent       :integer          default(0), not null
#  assigned_to_user_id :integer
#  last_opened_at      :datetime
#  opened_at           :datetime
#  turnaround_time     :integer          default(0), not null
#  media_channel_id    :integer
#  deleted_at          :datetime
#  assigned_at         :datetime
#  result              :string(20)       default(""), not null
#  data                :json             default({}), not null
#  created_by_user_id  :integer
#
# Indexes
#
#  index_tasks_on_deleted_at  (deleted_at)
#

FactoryGirl.define do
  factory :task do
    state 'new'
    association :media_channel, factory: :media_channel_email
    association :service_channel, factory: :service_channel
    factory :task_with_messages do
      ignore do
        messages_amount 5
      end
      after(:create) do |task, evaluator|
        create_list(:message, evaluator.messages_amount, task: task)
      end
    end
  end
end
