class AddCompanyToShipmentMethod < ActiveRecord::Migration
  def change
    add_reference :shipment_methods, :company, index: true, foreign_key: true
  end
end
