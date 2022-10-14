class AddCustomerToOrder < ActiveRecord::Migration
  def change
    add_reference :chatbot_orders, :customer, foreign_key: true
  end
end
