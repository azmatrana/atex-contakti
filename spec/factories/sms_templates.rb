# == Schema Information
#
# Table name: sms_templates
#
#  id                 :integer          not null, primary key
#  title              :string(100)      default(""), not null
#  text               :text
#  kind               :string(20)       default(""), not null
#  service_channel_id :integer
#  location_id        :integer
#  company_id         :integer
#  author_id          :integer
#  created_at         :datetime
#  updated_at         :datetime
#  visibility         :string(20)       default(""), not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sms_template do
    title { ::FFaker::Lorem.words(2).join(' ') }
    text { ::FFaker::Lorem.words(10).join(' ') }
    service_channel
    factory :agent_sms_template do
      kind 'agent'
    end
    factory :manager_sms_template do
      kind 'manager'
    end
  end
end
