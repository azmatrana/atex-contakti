require 'rails_helper'

describe ProcessScheduledReportsWorker do

  subject { ::ProcessScheduledReportsWorker.new }
  let(:report) { ::FactoryGirl.create :report, scheduled: 'daily' }

  before(:each) do
    report
    allow_any_instance_of(::ScreenshotGenerator).to receive(:generate_report_screenshot).and_return ::File.join('test_screenshot.png')
    allow(::File).to receive(:read)
    allow_any_instance_of(::Mail::Message).to receive(:deliver)
  end

  it 'should immediately deliver report that was not delivered yet' do
    time_now = ::Time.current
    allow(::Time).to receive(:current).and_return(time_now)
    subject.perform
    expect(report.reload.last_sent_at.to_i).to eq(time_now.to_i)
  end
end
