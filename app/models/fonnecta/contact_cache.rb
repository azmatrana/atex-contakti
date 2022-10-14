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

class Fonnecta::ContactCache < ActiveRecord::Base
  self.table_name = 'fonnecta_contact_caches'
  belongs_to :company
  validates :phone_number, :company, presence: true
end
