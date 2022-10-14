# == Schema Information
#
# Table name: user_sessions
#
#  id          :integer          not null, primary key
#  session_id  :uuid             not null
#  user_id     :integer          not null
#  user_ip     :string(255)
#  user_agent  :string(255)
#  accessed_at :datetime
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_user_sessions_on_session_id              (session_id) UNIQUE
#  index_user_sessions_on_user_id                 (user_id)
#  index_user_sessions_on_user_id_and_session_id  (user_id,session_id)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_session, :class => 'User::Session' do
    session_id ""
    user_id 1
    user_ip "MyString"
    user_agent "MyString"
  end
end
