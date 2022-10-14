class ShipmentMethod < ActiveRecord::Base
    belongs_to :company
    validates_presence_of(:name, :company_id)
    validates :price, presence: :true, numericality: { greater_than_or_equal_to: 0 }
  end  