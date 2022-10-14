class CreateChatbotOrders < ActiveRecord::Migration
  def change
    create_table :chatbot_orders do |t|
      t.string :checkout_method
      t.string :shipment_method
      t.references :company
      t.float :total
      t.timestamps
    end
  end
end
