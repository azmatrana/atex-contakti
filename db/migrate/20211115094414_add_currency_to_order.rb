class AddCurrencyToOrder < ActiveRecord::Migration
  def change
    add_column :chatbot_orders, :currency, :string, default: '€'
  end
end
