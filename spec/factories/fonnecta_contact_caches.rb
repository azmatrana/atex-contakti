# == Schema Information
#
# Table name: fonnecta_contact_caches
#
#  id           :integer          not null, primary key
#  company_id   :integer          not null
#  phone_number :string(255)      not null
#  full_name    :string(255)      not null
#  created_at   :datetime
#  updated_at   :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fonnecta_contact_cache, :class => 'Fonnecta::ContactCache' do
    association :company, factory: :company
    phone_number "MyString"
    full_name "MyString"
  end
end
