class CreateChatbotOrderProducts < ActiveRecord::Migration
  def change
    create_table :chatbot_order_products do |t|
      t.references :chatbot_order
      t.references :chatbot_product
      t.integer :quantity
      t.float :price
      t.timestamps
    end
  end
end
