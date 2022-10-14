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

require 'rails_helper'

RSpec.describe SmsTemplate, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
