require 'spec_helper'

describe SipSettings do
  subject { FactoryGirl.create(:sip_settings) }

  it 'should have a valid factory' do
    expect(FactoryGirl.build :sip_settings).to be_valid
  end
end
