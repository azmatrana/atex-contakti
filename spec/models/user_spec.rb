# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(100)      default(""), not null
#  last_name              :string(250)      default(""), not null
#  title                  :string(100)      default(""), not null
#  mobile                 :string(100)      default(""), not null
#  company_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  is_online              :boolean          default(FALSE), not null
#  is_working             :boolean          default(FALSE), not null
#  started_working_at     :datetime
#  went_offline_at        :datetime
#  authentication_token   :string(36)       default(""), not null
#  media_channel_types    :text             default([]), is an Array
#  default_location_id    :integer
#  last_seen_tasks        :datetime
#  service_channel_id     :integer
#  signature              :string(255)
#
# Indexes
#
#  index_users_on_default_location_id   (default_location_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require 'rails_helper'

describe ::User do
  it { is_expected.to validate_presence_of(:company_id) }
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_and_belong_to_many(:service_channels) }
  it { is_expected.to have_and_belong_to_many(:locations) }
  it { is_expected.to have_and_belong_to_many(:reports) }
  it { is_expected.to have_and_belong_to_many(:managed_locations)
                      .class_name('Location')
                      .with_foreign_key('manager_id') }
  it { is_expected.to have_many(:media_channels).
                     class_name('MediaChannel').
                     through(:service_channels) }
  it { is_expected.to have_many(:tasks).class_name('Task').through(:media_channels) }
  it { is_expected.to have_many(:messages) }
  it { is_expected.to have_many(:timelogs) }
  it { is_expected.to have_many(:messages) }
  it { is_expected.to have_many(:sessions).class_name('User::Session').dependent(:destroy) }

  context '#media_channels' do
    let(:company) { ::FactoryGirl.create(:company) }
    let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
    let(:email) { service_channel.email_media_channel }
    let(:call) { service_channel.call_media_channel }
    let(:web_form) { service_channel.web_form_media_channel }
    let(:sip) { service_channel.sip_media_channel }
    let(:user) { ::FactoryGirl.create(:agent, company: company) }
    before :each do
      service_channel.users = [user]
    end
    context 'with empty media_channel_types' do
      before :each do
        user.media_channel_types = []
        user.save!
      end
      it 'should have return no media channels' do
        expect(user.media_channels).to eq([])
      end
    end
    context 'with only one media_channel_types' do
      before :each do
        user.media_channel_types = ['email']
        user.save!
      end
      it 'should have return proper media channels' do
        expect(user.media_channels).to eq([email])
      end
    end
    context 'with multiple media_channel_types' do
      before :each do
        user.media_channel_types = ['email', 'call']
        user.save!
      end
      it 'should have return proper media channels' do
        expect(user.media_channel_ids.sort).to eq([email.id, call.id].sort)
      end
    end
    context 'with all media_channel_types' do
      before :each do
        user.media_channel_types = ['email', 'call', 'web_form']
        user.save!
      end
      it 'should have return proper media channels' do
        expect(user.media_channel_ids.sort).to eq(service_channel.media_channel_ids.sort)
      end
    end
  end

  it 'should have a valid factory' do
    expect(::FactoryGirl.build :user).to be_valid
  end

  it 'should return numeric random password' do
    user = ::FactoryGirl.create :user
    expect(user.get_random_password).to match /\d{8}/
  end

end
