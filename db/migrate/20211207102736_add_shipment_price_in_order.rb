class AddShipmentPriceInOrder < ActiveRecord::Migration
  def change
    add_column :chatbot_orders, :shipment_price, :decimal, :precision => 8, :scale => 2, default: 0
  end
end
