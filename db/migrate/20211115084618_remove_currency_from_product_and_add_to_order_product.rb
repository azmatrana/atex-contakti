class RemoveCurrencyFromProductAndAddToOrderProduct < ActiveRecord::Migration
  def change
    remove_column :chatbot_products, :currency, :string
    add_column :chatbot_order_products, :currency, :string, default: '€'
  end
end
