require 'rails_helper'

RSpec.describe ::CompanyStatsUpdaterWorker do
  let(:company) { ::FactoryGirl.create(:company) }
  it { is_expected.to be_unique }
  it { is_expected.to be_retryable false }

  context '#perform' do
    it 'should not call ::ActiveAgentsService' do
      expect(::ActiveAgentsService).to_not receive(:new)
      subject.perform
    end
    it 'should call ::ActiveAgentsService' do
      company
      expect_any_instance_of(::ActiveAgentsService).to receive(:for_date).with(::Date.today).and_call_original
      subject.perform
    end
  end
end