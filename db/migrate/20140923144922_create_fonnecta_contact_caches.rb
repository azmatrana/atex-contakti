class CreateFonnectaContactCaches < ActiveRecord::Migration
  def change
    create_table :fonnecta_contact_caches do |t|
      t.integer :company_id, null: false
      t.string :phone_number, null: false
      t.string :full_name, null: false

      t.timestamps
    end
  end
end
