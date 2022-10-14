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

require 'spec_helper'

describe MediaChannel::WebForm do
  let (:web_form) { ::FactoryGirl.create(:media_channel_web_form) }
  context '#set_unbroken' do
    subject { web_form.set_unbroken }
    context 'active = true and broken = false' do
      before :each do
        web_form.update_columns(active: true, broken: false)
      end
      it 'should not change anything' do
        subject
        expect(web_form.active).to be_truthy
        expect(web_form.broken).to be_falsey
      end
    end
    context 'active = false and broken = false' do
      before :each do
        web_form.update_columns(active: false, broken: false)
      end
      it 'should not change anything' do
        subject
        expect(web_form.active).to be_falsey
        expect(web_form.broken).to be_falsey
      end
    end
    context 'active = false and broken = true' do
      before :each do
        web_form.update_columns(active: false, broken: true)
      end
      it 'should change state if no changes' do
        subject
        expect(web_form.active).to be_truthy
        expect(web_form.broken).to be_falsey
      end
      it 'should change state if changes was in imap settings' do
        web_form.imap_settings.description = 'wowowowowowow!'
        subject
        expect(web_form.active).to be_truthy
        expect(web_form.broken).to be_falsey
      end
    end
    context 'active = true and broken = false' do
      before :each do
        web_form.update_columns(active: true, broken: false)
      end
      it 'should not change state if no changes' do
        subject
        expect(web_form.active).to be_truthy
        expect(web_form.broken).to be_falsey
      end
      it 'should change state if changes was in imap settings' do
        web_form.imap_settings.user_name = ''
        subject
        expect(web_form.active).to be_falsey
        expect(web_form.broken).to be_falsey
      end
      it 'should not change state if set active as false' do
        web_form.active = false
        subject
        expect(web_form.active).to be_falsey
        expect(web_form.broken).to be_falsey
      end
    end
  end
end
