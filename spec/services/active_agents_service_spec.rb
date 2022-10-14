require 'rails_helper'
RSpec.describe ::ActiveAgentsService do
  let(:company) { ::FactoryGirl.create(:company) }
  let(:user) { ::FactoryGirl.create(:agent, company: company) }
  let(:user2) { ::FactoryGirl.create(:agent, company: company) }
  let(:user3) { ::FactoryGirl.create(:agent, company: company) }
  let(:user4) { ::FactoryGirl.create(:agent, company: company) }
  let(:timelog) { ::FactoryGirl.create(:timelog, user: user) }
  let(:timelog2) { ::FactoryGirl.create(:timelog, user: user2) }
  let(:timelog3) { ::FactoryGirl.create(:timelog, user: user3) }
  let(:timelog4) { ::FactoryGirl.create(:timelog, user: user4) }

  context '#for_date' do
    subject { described_class.new(company).for_date(::Date.today) }

    context 'with no time logs for company' do
      before :each do
        user2
        user3
      end
      it { is_expected.to eq(0) }
    end
    context 'with time logs for company' do
      before :each do
        timelog
        timelog2
        Delorean.time_travel_to '1 month ago'
        timelog3
        Delorean.back_to_the_present
      end
      it { is_expected.to eq(2) }
    end
  end
  context '::current_and_last_month' do
    subject { described_class.current_and_last_month }
    before :each do
      timelog
      timelog2
      Delorean.time_travel_to '1 month ago'
      timelog3
      Delorean.time_travel_to '1 month ago'
      timelog4
      Delorean.back_to_the_present
    end
    it { is_expected.to be_a(::Array) }
    it { is_expected.to eq([
      {company.id => 4},
      {company.id => 1}
    ])}
  end
end