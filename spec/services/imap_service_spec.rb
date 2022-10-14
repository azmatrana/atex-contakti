require 'rails_helper'
RSpec.describe ::ImapService do
  let(:media_channel) { ::FactoryGirl.create(:media_channel_email) }
  let(:imap_settings) { media_channel.imap_settings }
  let(:imap_instance) { double('Net::IMAP') }
  let(:service) { described_class.new(imap_settings) }

  subject { service }

  before :each do
    allow(::Net::IMAP).to receive(:new).and_return(imap_instance)
    allow(imap_instance).to receive(:login)
  end

  context '#new' do
    it 'should create proper ::Net::IMAP instance' do
      expect(::Net::IMAP).to receive(:new).with(
        imap_settings.server_name,
        imap_settings.port,
        imap_settings.use_ssl?
        )
      .and_return(imap_instance)
      subject
    end
    it 'should call login with proper params' do
      expect(imap_instance).to receive(:login).with(imap_settings.user_name, imap_settings.password)
      subject
    end
  end

  context '#disconnect' do
    it 'should call Net::IMAP#disconnect' do
      allow(imap_instance).to receive(:disconnected?).and_return(false)
      expect(imap_instance).to receive(:disconnect)
      service.disconnect
    end
    it 'should not call Net::IMAP#disconnect if already disconnected' do
      allow(imap_instance).to receive(:disconnected?).and_return(true)
      expect(imap_instance).to_not receive(:disconnect)
      service.disconnect
    end
  end

  context '::fetch_emails' do
    let(:service_instance) { double("#{described_class}") }
    subject { described_class.fetch_emails(media_channel) }
    before :each do
      allow(described_class).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:fetch_from_imap)
    end
    it 'should call ::new' do
      expect(described_class).to receive(:new).with(imap_settings).and_return(service_instance)
      subject
    end

    it 'should call #fetch_from_imap' do
      expect(service_instance).to receive(:fetch_from_imap).with(nil, media_channel.created_at)
      subject
    end

    it 'should call #fetch_from_imap with custom start_date' do
      custom_date = ::Time.current
      expect(service_instance).to receive(:fetch_from_imap).with(nil, custom_date)
      described_class.fetch_emails(media_channel, custom_date)
    end

    it 'should call #fetch_from_imap with last_message' do
      last_message = double('last_message')
      allow(::Message).to receive_message_chain(:joins, :where, :where, :not, :order, :last).and_return(last_message)
      expect(service_instance).to receive(:fetch_from_imap).with(last_message, media_channel.created_at)
      subject
    end

    it 'should call media_channel.add_task' do
      mail = double('mail')
      email_text = double('email_text')
      msg_uid = double('msg_uid')
      expect(media_channel).to receive(:add_task).with(mail, email_text, msg_uid)
      expect(service_instance).to receive(:fetch_from_imap).and_yield(mail, email_text, msg_uid)
      subject
    end

  end
end