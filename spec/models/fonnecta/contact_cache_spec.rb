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

require 'rails_helper'

RSpec.describe Fonnecta::ContactCache, type: :model do
  it { is_expected.to validate_presence_of(:company) }
  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to belong_to(:company) }
end
