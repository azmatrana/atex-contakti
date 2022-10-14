# == Schema Information
#
# Table name: fonnecta_credentials
#
#  id              :integer          not null, primary key
#  client_id       :string(255)      not null
#  client_secret   :string(255)      not null
#  token           :string(255)
#  token_taken_at  :datetime
#  token_expire_in :integer
#  created_at      :datetime
#  updated_at      :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fonnecta_credential, class: 'Fonnecta::Credential' do
    client_id "MyString"
    client_secret "MyString"
  end
end
