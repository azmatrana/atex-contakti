# == Schema Information
#
# Table name: imap_settings
#
#  id             :integer          not null, primary key
#  server_name    :string(100)      default(""), not null
#  user_name      :string(100)      default(""), not null
#  password       :string(100)      default(""), not null
#  description    :text             default(""), not null
#  created_at     :datetime
#  updated_at     :datetime
#  port           :integer          default(143)
#  use_ssl        :boolean          default(FALSE)
#  from_full_name :string(250)      default(""), not null
#  from_email     :string(250)      default(""), not null
#  company_id     :integer
#

FactoryGirl.define do
  factory :imap_settings, class: 'ImapSettings' do
    server_name { ::FFaker::Internet.domain_name }
    user_name { ::FFaker::Internet.user_name }
    password 'password'
    description { ::FFaker::Lorem.words.join(' ') }
    port 143
    use_ssl true
    from_full_name { ::FFaker::Name.name }
    from_email { ::FFaker::Internet.email }
  end
end
