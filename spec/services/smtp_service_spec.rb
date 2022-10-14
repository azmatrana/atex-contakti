require 'rails_helper'

RSpec.describe ::SmtpService do
  let(:company) { ::FactoryGirl.create(:company) }
  let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
  let(:user) { ::FactoryGirl.create :agent, company: company }
  let(:media_channel) { ::FactoryGirl.create(:media_channel_email, service_channel: service_channel) }
  let(:task) { ::FactoryGirl.create(:task, service_channel: service_channel, media_channel: media_channel) }
  let(:message) { ::FactoryGirl.create(:message, task: task, user: user) }
  let(:service) { described_class.new(message) }

  subject { service }

  context '#email' do
    subject { super().email }
    it { is_expected.to be_a(::Mail::Message) }
    context 'charset' do
      subject { super().charset }
      it { is_expected.to eq('UTF-8') }
    end
    context 'content_transfer_encoding' do
      subject { super().content_transfer_encoding }
      it { is_expected.to eq('8bit') }
    end
    context 'subject' do
      subject { super().subject }
      it { is_expected.to eq(message.title) }
    end
    context 'from' do
      subject { super().from }
      it { is_expected.to eq([message.from]) }
    end
    context 'to' do
      subject { super().to }
      it { is_expected.to eq([message.to]) }
    end
    context 'body' do
      subject { super().text_part.body.decoded }
      it { is_expected.to eq(message.description) }
    end
  end

  context '#settings' do
    subject { super().settings }
    it { is_expected.to be_a(::SmtpSettings) }
    it { is_expected.to eq(service_channel.email_media_channel.smtp_settings) }
  end

  context '#smtp_settings' do
    subject { super().smtp_settings }
    it { is_expected.to eq({
      address:        service_channel.email_media_channel.smtp_settings.server_name,
      port:           service_channel.email_media_channel.smtp_settings.port,
      user_name:      service_channel.email_media_channel.smtp_settings.user_name,
      password:       service_channel.email_media_channel.smtp_settings.password,
      enable_ssl:     service_channel.email_media_channel.smtp_settings.use_ssl?,
      authentication: service_channel.email_media_channel.smtp_settings.get_auth_method
    }) }
  end

  context '#delivery_handler' do
    subject { super().delivery_handler }
    it { is_expected.to be_a(::Mail::SMTP) }
    it 'should create proper ::Mail::SMTP instance' do
      expect(::Mail::SMTP).to receive(:new).with(service.smtp_settings)
      subject
    end
  end

  context '#include_attachments' do
    subject { super().include_attachments }
    before :each do
      ::FactoryGirl.create(:message_attachment, message: message)
      message.reload
    end
    it 'should add attachment to email' do
      subject
      expect(service.email.attachments.size).to eq(1)
      email_attachment = service.email.attachments.first
      expect(email_attachment.filename).to eq('attachment.txt')
    end
  end

  context '#send_email' do
    let(:email) { service.email }
    subject { super().send_email }
    before :each do
      allow(email).to receive(:deliver)
    end
    it 'should call #include_attachments' do
      expect(service).to receive(:include_attachments)
      subject
    end
    it 'should set delivery handler' do
      expect(email).to receive(:delivery_handler=).with(service)
      subject
    end
    it 'should call deliver' do
      expect(email).to receive(:deliver)
      subject
    end
    context 'with attachments' do
      before :each do
        ::FactoryGirl.create(:message_attachment, message: message)
        message.reload
        message.save!
      end
      it 'should create email with attachments and proper body' do
        service.send_email
        expect(email.attachments.size).to eq(1)
        expect(email.parts.size).to eq(2)
        expect(email.text_part.body.decoded).to eq(message.description)
      end
    end
  end

end
