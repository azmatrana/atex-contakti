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

describe MediaChannel do
  let(:service_channel) { ::FactoryGirl.create :service_channel }
  let(:email_media_channel) { service_channel.email_media_channel }
  let(:uuid) { ::SecureRandom.uuid }
  let(:existing_task) { ::FactoryGirl.create(:task, media_channel: email_media_channel, service_channel: service_channel, uuid: uuid) }
  let(:first_message) { ::FactoryGirl.create(:message, task: existing_task, channel_type: 'email', from: 'user@gmail.com') }
  let(:agent) { ::FactoryGirl.create(:agent, company: service_channel.company ) }
  subject { email_media_channel }

  context '#add_task' do

    let(:mail) do
      ::Mail.new do
        from 'user@gmail.com'
        to 'dotpromotest2@yahoo.com'
        subject 'Test Subject'
        body 'Test message'
      end
    end

    let(:test_id) { 2 }

    it 'should add new message to existing task if a this email is a reply' do
      mail.body = "Test Message" + first_message.get_signature
      subject.add_task(mail, mail.body.decoded, test_id)
      existing_task.reload
      expect(::Task.count).to eq(1)
      expect(existing_task.messages.count).to eq(2)
    end

    it 'should add new task and message' do
      subject.add_task(mail, mail.body.decoded, test_id)
      expect(::Task.count).to eq(1)
      task = ::Task.last
      expect(task.messages.count).to eq(1)
      expect(task.state).to eq('new')
    end

    it 'should change state of task if task not assigned to agent' do
      existing_task.state = 'new'
      existing_task.agent = nil
      existing_task.save!
      mail.body = "Test Message" + first_message.get_signature
      subject.add_task(mail, mail.body.decoded, test_id)
      existing_task.reload
      expect(existing_task.state).to eq('new')
      expect(existing_task.messages.count).to eq(2)
    end

    it 'should change state of task if task assigned to agent' do
      existing_task.state = 'ready'
      existing_task.agent = agent
      existing_task.save!
      mail.body = "Test Message" + first_message.get_signature
      subject.add_task(mail, mail.body.decoded, test_id)
      existing_task.reload
      expect(existing_task.state).to eq('open')
      expect(existing_task.messages.count).to eq(2)
    end

  end
end
