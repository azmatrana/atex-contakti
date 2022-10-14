require 'rails_helper'
require 'net/imap'

RSpec.describe ::MediaChannel::WebForm do
  let(:service_channel) { ::FactoryGirl.create(:service_channel) }
  let(:media_channel) { service_channel.web_form_media_channel }
  let(:imap_settings) { media_channel.imap_settings }
  let(:imap_instance) { double('Net::IMAP') }
  let(:service) { ::ImapService.new(imap_settings) }
  let(:fetch_result) { double('fetched_result') }
  let(:last_message) { double('last_message') }
  let(:agent) { ::FactoryGirl.create(:agent, company: service_channel.company) }
  let(:attr_hash) { { 'UID' => 'UUID', 'RFC822' => '' } }
  let(:yahoo_web_form_email) { ::Rails.root.join('spec', 'support', 'emails', 'webform_email_yahoo.eml').to_s }
  let(:enquiry_from_josephkokkinos) { ::Rails.root.join('spec', 'support', 'emails', 'enquiry_from_josephkokkinos.eml').to_s }

  before :each do
    media_channel.service_channel.user_ids = [agent.id]
    allow(::Net::IMAP).to receive(:new).and_return(imap_instance)
    allow(imap_instance).to receive(:login)
    allow(imap_instance).to receive(:disconnected?)
    allow(imap_instance).to receive(:disconnect)
    allow(imap_instance).to receive(:examine)
    allow(imap_instance).to receive(:search).and_return(['message_uuid'])
  end

  context '#email_regex' do
    it 'should match email from text', focus: true do
      fetch_email(imap_instance, enquiry_from_josephkokkinos, fetch_result)
      ImapService.fetch_emails(media_channel)
      message = Message.first
      expect(message.from).to eq('test@example.com')
    end

    it 'should not match email from text' do
      fetch_email(imap_instance, yahoo_web_form_email, fetch_result)
      ImapService.fetch_emails(media_channel)
      message = Message.first
      expect(message.from).to eq('Yahoo@communications.yahoo.com')
    end
  end
end
