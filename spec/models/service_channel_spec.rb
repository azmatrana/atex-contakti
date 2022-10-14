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
#  index_service_channels_on_deleted_at  (deleted_at)
#

require 'rails_helper'

describe ServiceChannel do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_one(:email_media_channel).class_name('MediaChannel::Email').dependent(:destroy) }
  it { is_expected.to have_one(:web_form_media_channel).class_name('MediaChannel::WebForm').dependent(:destroy) }
  it { is_expected.to have_one(:call_media_channel).class_name('MediaChannel::Call').dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }
  it { is_expected.to have_many(:sms_templates) }
  it { is_expected.to have_many(:media_channels) }
  it { is_expected.to have_and_belong_to_many(:users) }
  it { is_expected.to have_and_belong_to_many(:locations) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:locations) }
  it { is_expected.to validate_numericality_of(:red_alert_days).only_integer.allow_nil }
  it { is_expected.to validate_numericality_of(:yellow_alert_days).only_integer.allow_nil }
  it { is_expected.to validate_numericality_of(:red_alert_hours).allow_nil }
  it { is_expected.to validate_numericality_of(:yellow_alert_hours).allow_nil }
  it { is_expected.to accept_nested_attributes_for(:email_media_channel).update_only(true) }
  it { is_expected.to accept_nested_attributes_for(:web_form_media_channel).update_only(true) }
  it { is_expected.to accept_nested_attributes_for(:call_media_channel).update_only(true) }
  it { is_expected.to accept_nested_attributes_for(:locations) }
  it { is_expected.to accept_nested_attributes_for(:users) }

  context 'instance' do
    subject { ::FactoryGirl.create(:service_channel) }

    context 'yellow_alert_limit_in_hours' do

      it 'should correctly calculate hours in case of decimal hour value' do
        subject.yellow_alert_hours = 3.5
        expect(subject.yellow_alert_limit_in_hours).to eq(27.5)
      end

    end
  end
end
