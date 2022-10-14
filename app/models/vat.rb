class Vat < ActiveRecord::Base
  belongs_to :company
  has_many :products, class_name: 'Chatbot::Product', foreign_key: :vat_id

  validates :vat_percentage, presence: :true, uniqueness: {
              scope: :company_id }, numericality: { greater_than_or_equal_to: 0, less_than: 100 }
end
