# == Schema Information
#
# Table name: locations
#
#  id             :integer          not null, primary key
#  name           :string(250)      default(""), not null
#  street_address :string(250)      default(""), not null
#  zip_code       :string(20)       default(""), not null
#  city           :string(100)      default(""), not null
#  timezone       :string(20)       default(""), not null
#  company_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#

require 'rails_helper'

describe Location do

  it 'should have a valid factory' do
    expect(::FactoryGirl.build(:location)).to be_valid
  end

end
