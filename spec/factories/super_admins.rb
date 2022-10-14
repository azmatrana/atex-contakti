# == Schema Information
#
# Table name: super_admins
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  username               :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#
# Indexes
#
#  index_super_admins_on_email                 (email) UNIQUE
#  index_super_admins_on_reset_password_token  (reset_password_token) UNIQUE
#  index_super_admins_on_username              (username) UNIQUE
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :super_admin do
  end
end
