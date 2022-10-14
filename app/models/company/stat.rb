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

class Company::Stat < ActiveRecord::Base
  belongs_to :company
  validates :company, :date, presence: true
end
