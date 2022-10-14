require 'rails_helper'

RSpec.describe ::FetchEmailsFromChannelWorker do
  let(:media_channel) { ::FactoryGirl.create(:media_channel_email) }

  it { is_expected.to be_unique }

  context '#perform' do
    subject { super().perform(media_channel.id) }

    it 'should call ::ImapService.fetch_emails' do
      expect(::ImapService).to receive(:fetch_emails).with(media_channel)
      subject
    end
  end
end