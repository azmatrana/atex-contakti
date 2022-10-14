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

FactoryGirl.define do
  factory :company do
    name { ::FFaker::Company.name }
    street_address { ::FFaker::Address.street_address }
    zip_code { ::FFaker::AddressFI.zip_code }
    city { ::FFaker::Address.city }
    sequence(:code)
    time_zone 'Helsinki'
  end
end
