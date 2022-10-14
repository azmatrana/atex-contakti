# == Schema Information
#
# Table name: smtp_settings
#
#  id          :integer          not null, primary key
#  server_name :string(100)      default(""), not null
#  user_name   :string(100)      default(""), not null
#  password    :string(100)      default(""), not null
#  description :text             default(""), not null
#  port        :integer          default(465), not null
#  use_ssl     :boolean          default(TRUE), not null
#  company_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  auth_method :string(20)       default(""), not null
#

FactoryGirl.define do
  factory :smtp_settings, class: 'SmtpSettings' do
    server_name { ::FFaker::Internet.domain_name }
    user_name { ::FFaker::Internet.user_name }
    password 'password'
    description { ::FFaker::Lorem.words.join(' ') }
    use_ssl true
    auth_method 'NTLM'
  end
end
