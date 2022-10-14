require 'rails_helper'

describe ReportsHelper do

  let(:report) { ::FactoryGirl.create :summary_report }

  context '#format_date_range' do

    it 'should return single date for date ranges of less than 1 day' do
      report.starts_at = ::Time.zone.parse('1970/1/1')
      report.ends_at = report.starts_at + 1.day - 1.minute
      result = helper.format_date_range(report)
      expect(result).to eq('01/01/1970')
    end

    it 'should return empty value if starts_at or ends_at are empty' do
      report.starts_at = ''
      result = helper.format_date_range(report)
      expect(result).to be_empty
    end

    it 'should return date range for ranges longer than 1 day' do
      report.starts_at = ::Time.zone.parse('1970/1/1')
      report.ends_at = report.starts_at + 7.days - 1.minute
      result = helper.format_date_range(report)
      expect(result).to eq('01/01/1970-07/01/1970')
    end

  end

end
