class AddVatAndWithVatToProductAndOrderProduct < ActiveRecord::Migration
  def change
    add_column :chatbot_products, :with_vat, :boolean, default: false
    add_column :chatbot_order_products, :with_vat, :boolean, default: false
    add_reference :chatbot_products, :vat, foreign_key: true
    add_column :chatbot_order_products, :vat_percentage, :integer, default: 0
  end
end
