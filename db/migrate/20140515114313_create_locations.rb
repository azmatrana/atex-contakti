class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name, limit: 250, null: false, default: ''
      t.string :street_address, limit: 250, null: false, default: ''
      t.string :zip_code, limit: 20, null: false, default: ''
      t.string :city, limit: 100, null: false, default: ''
      t.string :timezone, limit: 20, null: false, default: ''
      t.integer :company_id
      t.integer :manager_id
      t.timestamps
    end
  end
end
