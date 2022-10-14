class ChangeColumnTypeOfPriceInProductAndOrderProduct < ActiveRecord::Migration
  def change
    change_column :chatbot_products, :price, :decimal, :precision => 8, :scale => 2
    change_column :chatbot_order_products, :price, :decimal, :precision => 8, :scale => 2
  end
end
