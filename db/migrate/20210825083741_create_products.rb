class CreateProducts < ActiveRecord::Migration
  def change
    create_table :chatbot_products do |t|
      t.string :title, null: false
      t.string :currency
      t.float :price
      t.references :company
      t.timestamps
    end
  end
end
