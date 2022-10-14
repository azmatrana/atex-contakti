# == Schema Information
#
# Table name: media_channels
#
#  id                 :integer          not null, primary key
#  service_channel_id :integer
#  type               :string(50)       default(""), not null
#  imap_settings_id   :integer
#  smtp_settings_id   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  group_id           :string(255)      default(""), not null
#  deleted_at         :datetime
#  autoreply_text     :text
#  active             :boolean          default(TRUE), not null
#  broken             :boolean          default(FALSE), not null
#  name_check         :boolean          default(FALSE), not null
#  send_autoreply     :boolean          default(TRUE), not null
#  yellow_alert_hours :decimal(4, 2)
#  yellow_alert_days  :integer
#  red_alert_hours    :decimal(4, 2)
#  red_alert_days     :integer
#  chat_settings_id   :integer
#
# Indexes
#
#  index_media_channels_on_deleted_at  (deleted_at)
#

FactoryGirl.define do
  factory :media_channel_call, class: 'MediaChannel::Call' do
    group_id '2'
    trait :autoreply do
      autoreply_text { ::FFaker::Lorem.paragraph }
    end
  end
end

FactoryGirl.define do
  factory :media_channel_email, class: 'MediaChannel::Email' do
    imap_settings
    smtp_settings
  end
  factory :media_channel_web_form, class: 'MediaChannel::WebForm' do
    imap_settings
    smtp_settings
  end
  factory :media_channel_sip, class: "MediaChannel::Sip" do
    sip_settings
  end
end
