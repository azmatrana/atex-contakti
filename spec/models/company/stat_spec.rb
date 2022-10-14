# == Schema Information
#
# Table name: company_stats
#
#  id                    :integer          not null, primary key
#  company_id            :integer          not null
#  date                  :date             not null
#  active_agents         :integer          default(0), not null
#  name_checks           :integer          default(0), not null
#  created_at            :datetime
#  updated_at            :datetime
#  sms_sent              :integer          default(0), not null
#  sms_received          :integer          default(0), not null
#  call_tasks_received   :integer          default(0), not null
#  call_task_name_checks :integer          default(0), not null
#  call_task_autoreplies :integer          default(0), not null
#

require 'rails_helper'

RSpec.describe Company::Stat, :type => :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to validate_presence_of(:company) }
  it { is_expected.to validate_presence_of(:date) }
end
