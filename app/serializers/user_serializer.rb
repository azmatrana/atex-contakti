# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(100)      default(""), not null
#  last_name              :string(250)      default(""), not null
#  title                  :string(100)      default(""), not null
#  mobile                 :string(100)      default(""), not null
#  company_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  is_online              :boolean          default(FALSE), not null
#  is_working             :boolean          default(FALSE), not null
#  started_working_at     :datetime
#  went_offline_at        :datetime
#  authentication_token   :string(36)       default(""), not null
#  media_channel_types    :text             default([]), is an Array
#  default_location_id    :integer
#  last_seen_tasks        :datetime
#  service_channel_id     :integer
#  signature              :string(255)
#
# Indexes
#
#  index_users_on_default_location_id   (default_location_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name
end
