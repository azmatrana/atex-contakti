require 'rails_helper'

describe SmsSenderWorker do
  let(:company) { ::FactoryGirl.create(:company) }

  before :each do
    allow(Labyrintti).to receive(:user).and_return('user')
    allow(Labyrintti).to receive(:password).and_return('password')
  end

  it 'should send sms through labyrintti' do
    expect_any_instance_of(::Labyrintti::SMS).to receive(:send_text).and_return({ok:true})
    subject.perform('+12345', 'text', company.id)
  end

  it 'should increment company stat sms sent counter' do
    company.current_stat
    allow_any_instance_of(::Labyrintti::SMS).to receive(:send_text).and_return({ok:true})
    expect(::Company::Stat.last.sms_sent).to eq(0)
    subject.perform('+12345', 'text', company.id)
    expect(::Company::Stat.last.sms_sent).to eq(1)
  end

end