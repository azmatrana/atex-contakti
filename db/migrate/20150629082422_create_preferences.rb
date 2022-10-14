class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.string :name
      t.integer :company_id
      t.boolean :state, default: false

      t.timestamps
    end
  end
end
