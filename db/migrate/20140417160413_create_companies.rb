class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string  :name,           limit: 100, null: false, default: ''
      t.string  :street_address, limit: 250, null: false, default: ''
      t.string  :zip_code,       limit: 100, null: false, default: ''
      t.string  :city,           limit: 100, null: false, default: ''
      t.string  :code,           limit: 100, null: false, default: ''
      t.integer :contact_person_id
      t.timestamps
    end
  end
end
