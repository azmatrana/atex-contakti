class AddPriceInShipmentMethod < ActiveRecord::Migration
  def change
    add_column :shipment_methods, :price, :decimal, :precision => 8, :scale => 2
  end
end
