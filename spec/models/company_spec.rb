# == Schema Information
#
# Table name: companies
#
#  id                :integer          not null, primary key
#  name              :string(100)      default(""), not null
#  street_address    :string(250)      default(""), not null
#  zip_code          :string(100)      default(""), not null
#  city              :string(100)      default(""), not null
#  code              :string(100)      default(""), not null
#  contact_person_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#  time_zone         :string(255)      default("Helsinki"), not null
#  inactive          :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe Company, type: :model do
  let(:company) { ::FactoryGirl.create(:company) }

  it { should have_many(:users) }
  it { should have_many(:stats).class_name('Company::Stat') }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }

  context '#current_stat' do
    it 'should create new stat entry' do
      expect { company.current_stat }.to change(::Company::Stat, :count).by(1)
    end
    it 'should have proper date' do
      expect(company.current_stat.date).to eq(::Time.current.beginning_of_month.to_date)
    end
  end

end
