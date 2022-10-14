require 'spec_helper'
RSpec.describe ::MediaChannelService do
  let(:media_channel) { ::FactoryGirl.create(:media_channel_web_form) }
  let(:service) { described_class.new(media_channel.id) }
  subject { service }

  context 'MediaChannel.active = true' do
    subject { media_channel }
    before :each do
      media_channel.update_column(:active, true)
    end
    context 'on checking both imap and smtp broken' do
      before :each do
        allow(::ImapService).to receive(:test).and_return({ success: false })
        allow(::SmtpService).to receive(:test).and_return({ success: false })
        service.check_active_state
        media_channel.reload
      end
      it 'should set active to false and broken to true' do
        expect(media_channel.active).to be_falsey
        expect(media_channel.broken).to be_truthy
      end
    end
    context 'on checking both imap and smtp success' do
      before :each do
        allow(::ImapService).to receive(:test).and_return({ success: true })
        allow(::SmtpService).to receive(:test).and_return({ success: true })
        service.check_active_state
        media_channel.reload
      end
      it 'should set broken to false' do
        expect(media_channel.broken).to be_falsey
      end
    end
    context 'on checking imap broken and smtp success' do
      before :each do
        allow(::ImapService).to receive(:test).and_return({ success: false })
        allow(::SmtpService).to receive(:test).and_return({ success: true })
        service.check_active_state
        media_channel.reload
      end
      it 'should set active to false and broken to true' do
        expect(media_channel.active).to be_falsey
        expect(media_channel.broken).to be_truthy
      end
    end
    context 'on checking imap success and smtp broken' do
      before :each do
        allow(::ImapService).to receive(:test).and_return({ success: true })
        allow(::SmtpService).to receive(:test).and_return({ success: false })
        service.check_active_state
        media_channel.reload
      end
      it 'should set active to false and broken to true' do
        expect(media_channel.active).to be_falsey
        expect(media_channel.broken).to be_truthy
      end
    end
  end
end
