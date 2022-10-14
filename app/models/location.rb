# == Schema Information
#
# Table name: locations
#
#  id             :integer          not null, primary key
#  name           :string(250)      default(""), not null
#  street_address :string(250)      default(""), not null
#  zip_code       :string(20)       default(""), not null
#  city           :string(100)      default(""), not null
#  timezone       :string(20)       default(""), not null
#  company_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class Location < ActiveRecord::Base
  SEARCH_KEYS = %i(name street_address zip_code city)
  belongs_to              :company
  has_and_belongs_to_many :users
  has_and_belongs_to_many :service_channels
  has_and_belongs_to_many :reports
  has_and_belongs_to_many :managers, class_name: '::User', join_table: 'locations_managers', association_foreign_key: 'manager_id'
  has_many                :sms_templates

  accepts_nested_attributes_for :managers
  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :service_channels

  scope :for_company, lambda { |company_id| where(:company_id => company_id) }

  validates :name, :street_address, :zip_code, :city, presence: true
  validates :zip_code, numericality: true

  include WeeklySchedulable

  # Ransack
  ransacker :search_cond do |parent|
    Arel::Nodes::NamedFunction.new('LOWER',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [' ', *SEARCH_KEYS.map { |x| parent.table[x] }])])
  end
end
