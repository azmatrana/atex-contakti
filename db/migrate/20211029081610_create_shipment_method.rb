class CreateShipmentMethod < ActiveRecord::Migration
  def change
    create_table :shipment_methods do |t|
      t.string :name;
    end
  end
end