class CreateProductImages < ActiveRecord::Migration
  def change
    create_table :product_images do |t|
      t.string :file, null: false
      t.string :file_name, null: false
      t.integer :file_size
      t.string :file_type
      t.references :chatbot_product
      t.timestamps
    end
  end
end
