# == Schema Information
#
# Table name: timelogs
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  minutes_worked :integer
#  created_at     :datetime
#  updated_at     :datetime
#  minutes_paused :integer          default(0), not null
#

FactoryGirl.define do
  factory :timelog do
    association :user, factory: :agent
    minutes_worked 480
    minutes_paused 60
  end
end
