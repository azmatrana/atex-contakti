require 'rails_helper'

RSpec.describe ::DanthesPushWorker do
  let(:message) { ::FactoryGirl.create(:message) }
  let(:task) { ::FactoryGirl.create(:task) }
  it { is_expected.to be_unique }

  it 'should call DanthesService.push_to_browser for message' do
    expect(::DanthesService).to receive(:new).with(message).and_call_original
    expect_any_instance_of(::DanthesService).to receive(:push_to_browser)
    subject.perform(message.class.name, message.id)
  end

  it 'should call DanthesService.push_to_browser for task' do
    expect(::DanthesService).to receive(:new).with(task).and_call_original
    expect_any_instance_of(::DanthesService).to receive(:push_to_browser)
    subject.perform(task.class.name, task.id)
  end

end