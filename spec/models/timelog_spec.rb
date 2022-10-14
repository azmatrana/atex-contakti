# == Schema Information
#
# Table name: timelogs
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  minutes_worked :integer
#  created_at     :datetime
#  updated_at     :datetime
#  minutes_paused :integer          default(0), not null
#

require 'rails_helper'

describe Timelog do

  it 'should have a valid factory' do
    expect(::FactoryGirl.build :timelog).to be_valid
  end

end
