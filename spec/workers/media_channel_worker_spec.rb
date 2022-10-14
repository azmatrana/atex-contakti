require 'rails_helper'

describe ::MediaChannelWorker do
  let(:media_channel) { ::FactoryGirl.create(:media_channel_web_form) }

  it { is_expected.to be_unique }

  context '#perform' do
    it 'should call MediaChannelService' do
      expect(::MediaChannelService).to receive(:new).with(media_channel.id).and_call_original
      expect_any_instance_of(::MediaChannelService).to receive(:check_active_state)
      subject.perform(media_channel.id)
    end
  end
end
