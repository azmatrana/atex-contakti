require 'rails_helper'

RSpec.describe ::EmailSenderWorker do
  let(:message) { ::FactoryGirl.create(:message) }

  it 'should call SmtpService.send_email' do
    expect(::SmtpService).to receive(:new).with(message).and_call_original
    expect_any_instance_of(::SmtpService).to receive(:send_email)
    subject.perform(message.id)
  end
end