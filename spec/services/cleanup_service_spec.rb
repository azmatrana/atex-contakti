require 'spec_helper'

RSpec.describe ::CleanupService do
  let(:company) { ::FactoryGirl.create(:company) }
  let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
  let(:agent) { ::FactoryGirl.create(:user, company: company) }

  context 'removed service channel' do
    it 'should not remove' do
      ::FactoryGirl.create_list(:task_with_messages, 5, service_channel: service_channel, state: 'new')
      service_channel.destroy
      subject.run
      expect(::ServiceChannel.unscoped.count).to eq(1)
      expect(::Task.unscoped.count).to eq(5)
      expect(::Message.unscoped.count).to eq(25)
    end
    it 'should remove' do
      Delorean.time_travel_to('31 days ago') do
        ::FactoryGirl.create_list(:task_with_messages, 5, service_channel: service_channel, state: 'new')
        service_channel.destroy
      end
      subject.run
      expect(::ServiceChannel.unscoped.count).to eq(0)
      expect(::Task.unscoped.count).to eq(0)
      expect(::Message.unscoped.count).to eq(0)
    end
  end

  it 'should call remove_file! on attachment' do
    expect_any_instance_of(::Message::Attachment).to receive(:remove_file!).and_call_original
    Delorean.time_travel_to('31 days ago') do
      task = ::FactoryGirl.create(:task, service_channel: service_channel, state: 'ready')
      task.messages << ::FactoryGirl.create(:message_with_attachment, task: task)
    end
    expect(::ServiceChannel.unscoped.count).to eq(1)
    expect(::Task.unscoped.count).to eq(1)
    expect(::Message.unscoped.count).to eq(1)
    expect(::Message::Attachment.unscoped.count).to eq(1)
    subject.run
    expect(::ServiceChannel.unscoped.count).to eq(1)
    expect(::Task.unscoped.count).to eq(0)
    expect(::Message.unscoped.count).to eq(0)
    expect(::Message::Attachment.unscoped.count).to eq(0)
  end

  context 'closed tasks' do
    it 'should not remove all' do
      ::FactoryGirl.create_list(:task_with_messages, 5, service_channel: service_channel, state: 'ready')
      subject.run
      expect(::Task.unscoped.count).to eq(5)
      expect(::Message.unscoped.count).to eq(25)
      expect(::ServiceChannel.unscoped.count).to eq(1)
    end
    it 'should remove all' do
      Delorean.time_travel_to('31 days ago') do
        ::FactoryGirl.create_list(:task_with_messages, 5, service_channel: service_channel, state: 'ready')
        ::FactoryGirl.create_list(:task_with_messages, 5, service_channel: service_channel, state: 'new')
      end
      expect(::Task.unscoped.count).to eq(10)
      expect(::Message.unscoped.count).to eq(50)
      subject.run
      expect(::Task.unscoped.count).to eq(5)
      expect(::Message.unscoped.count).to eq(25)
      expect(::ServiceChannel.unscoped.count).to eq(1)
    end
  end
end
