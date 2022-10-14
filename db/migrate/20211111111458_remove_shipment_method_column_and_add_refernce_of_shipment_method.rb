class RemoveShipmentMethodColumnAndAddRefernceOfShipmentMethod < ActiveRecord::Migration
  def change
    remove_column :chatbot_orders, :shipment_method
    add_reference :chatbot_orders, :shipment_method, index: true
  end
end
