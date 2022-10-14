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

require 'rails_helper'

describe MediaChannel::Call do

  let(:service_channel) { ::FactoryGirl.create :service_channel }
  let(:call_media_channel) { ::FactoryGirl.create :media_channel_call, service_channel: service_channel }

  subject { call_media_channel }

  context '#add_task_from_hash' do

    it 'should add new message to existing task if a new task for this caller and call group id already exists' do
      existing_task = ::FactoryGirl.create :task, media_channel: subject
      first_message = ::FactoryGirl.create :message, task: existing_task, channel_type: 'call', from: '+358447474120'

      subject.add_task_from_hash({
        from:        '+358447474120',
        to:          '+358985646800',
        message_uid: 222,
        description: 'Bla bla bla description',
        group_id:    '2'
      })
      existing_task.reload

      expect(::Task.count).to eq(1)
      expect(existing_task.messages.count).to eq(2)
    end

    it 'should queue sms sending if autoreply is set' do
      call_media_channel_with_reply = ::FactoryGirl.create(:media_channel_call, :autoreply, service_channel: service_channel)
      call_media_channel_with_reply.add_task_from_hash({
        from:        '+358447474120',
        to:          '+358985646800',
        message_uid: 222,
        description: 'Bla bla bla description',
        group_id:    '2'
      })
      expect(::SmsSenderWorker).to have_enqueued_job('+358447474120', call_media_channel_with_reply.autoreply_text, service_channel.company_id)
    end

  end

  context '#add_task' do

    let(:mail) do
      ::Mail.new do
        from 'noreply@yv1.cuuma.fi'
        to 'dotpromotest2@yahoo.com'
        subject 'Asiakas on tavoittanut (800 )asiakaspalvelua 22.08.2014 12:34:30 numerosta +358447474120.'
        body 'Extension: +358985646800
              Callerid: +358447474120
              Date & time: 22.08.2014 12:34:30

              Company 1, Service Channel 2, 22.08.2014 12:34:30 , +358447474120'
      end
    end

    let(:test_id) { 12345 }

    it 'should add new message to existing task if a new task for this caller and call group id already exists' do
      existing_task = ::FactoryGirl.create :task, media_channel: subject
      first_message = ::FactoryGirl.create :message, task: existing_task, channel_type: 'call', from: '+358447474120'

      subject.add_task(mail, mail.body, test_id)
      existing_task.reload

      expect(::Task.count).to eq(1)
      expect(existing_task.messages.count).to eq(2)
    end

    it 'should not change state of task' do
      existing_task = ::FactoryGirl.create :task, media_channel: subject, state: 'new'
      ::FactoryGirl.create :message, task: existing_task, channel_type: 'call', from: '+358447474120'
      subject.add_task(mail, mail.body, test_id)
      existing_task.reload
      expect(existing_task.state).to eq('new')
    end

    it 'should create new task if no task for such caller exist' do
      existing_task = ::FactoryGirl.create :task, media_channel: subject
      first_message = ::FactoryGirl.create :message, task: existing_task, channel_type: 'call', from: '+358447474121'

      subject.add_task(mail, mail.body, test_id)
      existing_task.reload

      expect(::Task.count).to eq(2)
      expect(existing_task.messages.count).to eq(1)
    end

    it 'should create new task if a task for such caller exists, but is already closed' do
      existing_task = ::FactoryGirl.create :task, media_channel: subject, state: :ready
      first_message = ::FactoryGirl.create :message, task: existing_task, channel_type: 'call', from: '+358447474120'

      subject.add_task(mail, mail.body, test_id)
      existing_task.reload

      expect(::Task.count).to eq(2)
      expect(existing_task.messages.count).to eq(1)
    end

  end

  context '#check_group_id' do
    subject { call_media_channel.check_group_id }
    context 'active = true and broken = false' do
      before :each do
        call_media_channel.update_columns(active: true, broken: false)
      end
      it 'should not change anything' do
        subject
        expect(call_media_channel.active).to be_truthy
        expect(call_media_channel.broken).to be_falsey
      end
    end
    context 'active = false and broken = false' do
      before :each do
        call_media_channel.update_columns(active: false, broken: false)
      end
      it 'should not change anything' do
        subject
        expect(call_media_channel.active).to be_falsey
        expect(call_media_channel.broken).to be_falsey
      end
    end
    context 'active = false and broken = true' do
      before :each do
        call_media_channel.update_columns(active: false, broken: true)
      end
      it 'should change state if changes was in group_id and group_id not empty' do
        call_media_channel.group_id = 'dddd'
        subject
        expect(call_media_channel.active).to be_truthy
        expect(call_media_channel.broken).to be_falsey
      end
      it 'should change state if changes was in group_id and group_id is empty' do
        call_media_channel.group_id = ''
        subject
        expect(call_media_channel.active).to be_falsey
        expect(call_media_channel.broken).to be_truthy
      end
    end
    context 'active = true and broken = false' do
      before :each do
        call_media_channel.update_columns(active: true, broken: false)
      end
      it 'should not change state if no changes' do
        subject
        expect(call_media_channel.active).to be_truthy
        expect(call_media_channel.broken).to be_falsey
      end
      it 'should change state if changes was in group_id ' do
        call_media_channel.group_id = ''
        subject
        expect(call_media_channel.active).to be_falsey
        expect(call_media_channel.broken).to be_truthy
      end
      it 'should not change state if set active as false' do
        call_media_channel.active = false
        subject
        expect(call_media_channel.active).to be_falsey
        expect(call_media_channel.broken).to be_falsey
      end
    end
  end

end
