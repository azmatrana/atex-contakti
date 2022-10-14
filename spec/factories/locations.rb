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

FactoryGirl.define do
  factory :location do
    association :company, factory: :company
    name { ::FFaker::Lorem.words(2).join }
    street_address { ::FFaker::Address.street_address }
    zip_code '02124'
    city { ::FFaker::Address.city }
  end
end
