# == Schema Information
#
# Table name: reports
#
#  id                          :integer          not null, primary key
#  title                       :string(100)      default(""), not null
#  kind                        :string(20)       default(""), not null
#  starts_at                   :datetime
#  ends_at                     :datetime
#  company_id                  :integer
#  author_id                   :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  send_to_emails              :string(500)      default(""), not null
#  scheduled                   :string(255)      default(""), not null
#  last_sent_at                :datetime
#  media_channel_types         :text             default([]), is an Array
#  report_scope                :string(20)       default(""), not null
#  dashboard_layout_id         :integer
#  locale                      :string(20)
#  start_sending_at            :datetime
#  schedule_start_sent_already :boolean          default(FALSE), not null
#

FactoryGirl.define do
  factory :report, aliases: [:summary_report] do
    title 'Test Summary Report'
    kind 'summary'
    company
    starts_at { 1.day.ago }
    ends_at { ::Time.current }
    send_to_emails 'blaaaaaaa@blaaaaa.com'
    
    factory :comparison_report do
      title 'Test Comparison Report'
      kind 'comparison'
    end
  end

end
