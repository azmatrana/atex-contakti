# == Schema Information
#
# Table name: service_channels
#
#  id                 :integer          not null, primary key
#  name               :string(100)      default(""), not null
#  created_at         :datetime
#  updated_at         :datetime
#  yellow_alert_days  :integer
#  yellow_alert_hours :decimal(4, 2)
#  red_alert_days     :integer
#  red_alert_hours    :decimal(4, 2)
#  company_id         :integer
#  deleted_at         :datetime
#
# Indexes
#
# index_service_channels_on_deleted_at  (deleted_at)
#

FactoryGirl.define do

  factory :service_channel do
    association :company, factory: :company

    association :email_media_channel, factory: :media_channel_email
    association :web_form_media_channel, factory: :media_channel_web_form
    association :call_media_channel, factory: :media_channel_call
    association :sip_media_channel, factory: :media_channel_sip

    name { ::FFaker::Lorem.words.join(' ') }
    red_alert_days 1
    red_alert_hours 6
    yellow_alert_days 1
    yellow_alert_hours 0

    locations { [ ::FactoryGirl.create(:location) ] }
  end
end
