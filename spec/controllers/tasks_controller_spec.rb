require 'rails_helper'

describe TasksController, type: :controller do
  let(:company) { ::FactoryGirl.create :company }
  let(:user) { ::FactoryGirl.create :agent, company: company }
  let(:user2) { ::FactoryGirl.create :agent, company: company }
  let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
  let(:task) { ::FactoryGirl.create :task, service_channel: service_channel, media_channel: service_channel.email_media_channel }
  let(:message) { ::FactoryGirl.create :message, user_id: user.id, task_id: task.id }
  let(:reply_params) {
    {
      to:          'test123456@example.com',
      title:       'Bla bla title',
      description: 'Bla bla message'
    }
  }
  let(:forward_params) {
    {
      is_internal:    'true',
      to:             'vasya@example.com',
      title:          'Bla bla title',
      description:    'Bla bla message',
      in_reply_to_id: message.id
    }
  }
  let(:sms_params) {
    {
      is_sms:      '1',
      to:          '+380503456789',
      description: 'Bla bla message'
    }
  }

  before :each do
    service_channel.users << user
  end

  context '#update' do

    before(:each) do
      allow(::SmtpService).to receive(:send_email)
      allow(::I18n).to receive(:locale).and_return(:en)
      sign_in(user)
      message
    end

    context 'task is assigned to user' do
      before :each do
        task.state = 'open'
        task.assigned_to_user_id = user.id
        task.save!
      end
      it 'should post a reply to message', with_after_commit: true do
        put :update, id: task.id, reply: reply_params, format: :js
        expect(response).to be_success
        expect(response).to have_http_status(200)
        last_message = Message.order(:created_at).last
        expect(::Message.count).to eq(2)
        expect(last_message.number).to eq(2)
        expect(last_message.from).to eq(task.media_channel.imap_settings.from)
        expect(last_message.title).to eq('Bla bla title')
        expect(last_message.to).to eq('test123456@example.com')
        expect(last_message.description).to include(task.reload.uuid)
        expect(last_message.description).to include(last_message.id)
        expect(::EmailSenderWorker).to have_enqueued_job(last_message.id)
      end

      it 'should send an inner message', with_after_commit: true do
        put :update, reply: forward_params, id: task.id, format: :js
        expect(response).to be_success
        expect(response).to have_http_status(200)
        last_message = Message.order(:created_at).last
        expect(last_message.is_internal?).to be_truthy
        expect(last_message.to).to eq('Internal')
        expect(last_message.from).to eq(user.email)
        expect(::EmailSenderWorker).to have_enqueued_job(last_message.id)
      end

      it 'should send forward with attachments' do
        original_attachment = ::FactoryGirl.create(:message_attachment, message: message)
        expect(message.attachments.count).to eq(1)
        put :update, reply: forward_params, id: task.id, format: :js
        expect(response).to be_success
        expect(response).to have_http_status(200)
        last_message = Message.order(:created_at).last
        expect(last_message.is_internal?).to be_truthy
        expect(last_message.to).to eq('Internal')
        expect(last_message.attachments.count).to eq(1)
        attachment = last_message.attachments.first
        expect(attachment.file_name).to eq(original_attachment.file_name)
        expect(attachment.file_size).to eq(original_attachment.file_size)
        expect(attachment.read_attribute_before_type_cast('file').to_i).to_not eq(original_attachment.read_attribute_before_type_cast('file').to_i)
        expect(attachment.file.read).to eq(original_attachment.file.read)
      end

      it 'should send a sms', with_after_commit: true do
        put :update, reply: sms_params, id: task.id, format: :js
        expect(response).to be_success
        expect(response).to have_http_status(200)
        last_message = Message.order(:created_at).last
        expect(last_message.sms?).to be_truthy
        expect(last_message.to).to eq('+380503456789')
        expect(::SmsSenderWorker).to have_enqueued_job('+380503456789', 'Bla bla message', company.id)
      end
    end

    context 'task is not assigned to user' do
      context 'and in new state' do
        before :each do
          task.state = 'new'
          task.assigned_to_user_id = nil
          task.save!
        end

        it 'should post a reply to message', with_after_commit: true do
          put :update, id: task.id, reply: reply_params, format: :js
          expect(response).to be_success
          expect(response).to have_http_status(200)
        end
      end

      context 'and assigned to another user' do
        before :each do
          task.state = 'open'
          task.assigned_to_user_id = user2.id
          task.save!
        end

        it 'should get not allowed error' do
          put :update, id: task.id, reply: reply_params,  format:      :js
          expect(response).to_not be_success
          expect(response).to have_http_status(405)
        end
      end
    end
  end
  context '#danthes_subscribe' do
    before :each do
      sign_in(user)
    end
    it 'should return proper hash for danthes connect' do
      expect(::Danthes).to receive(:subscription).with(channel: "/media_channels/12/tasks").and_return(key1: 'value1', key2: 'value2')
      get :danthes_subscribe, channel_id: 12
      expect(response).to be_success
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to eq({ 'key1' => 'value1', 'key2' => 'value2' })
    end
    it 'should call Danthes.subscription' do
      expect(::Danthes).to receive(:subscription).with(channel: "/media_channels/12/tasks").and_call_original
      get :danthes_subscribe, channel_id: 12
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end
  end

end
