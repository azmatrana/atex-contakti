require 'rails_helper'

describe ::Helpers::TimeFormat do

  context '#format_minutes' do

    it 'should show only minutes for timespans of less than an hour' do
      expect(subject.format_minutes(55)).to eq('55m')
    end

    it 'should show hours and minutes for timespans > hour and < 1 day' do
      expect(subject.format_minutes(200)).to eq('3h 20m')
    end

    it 'should show days and hours for timespans > 1 day and < 1 week' do
      expect(subject.format_minutes(1515)).to eq('1d 1h 15m')
    end

    it 'should show weeks and days for timespans > 1 week' do
      expect(subject.format_minutes(27435)).to eq('19d 1h 15m')
    end

  end

end
