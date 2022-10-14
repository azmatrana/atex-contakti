require 'rails_helper'

describe TaskDecorator do
  subject { ::FactoryGirl.create(:task).decorate }
  it { should be_a Task }

  context '#format_time_till_red_alert' do
    
    it 'should format time' do
      subject.start!
      ::Delorean.time_travel_to(1.day.from_now)
      ::Delorean.time_travel_to(30.minutes.from_now)
      expect(subject.format_time_till_red_alert).to eq("5h 30min")
      ::Delorean.back_to_the_present
    end

    it 'should start counting upward if the minutes spent on task exceeded red alert limit' do
      subject.start!
      ::Delorean.time_travel_to(1.day.from_now)
      ::Delorean.time_travel_to(6.hours.from_now)
      ::Delorean.time_travel_to(25.minutes.from_now)
      expect(subject.format_time_till_red_alert).to eq("+25min")
      ::Delorean.back_to_the_present
    end

  end

end
