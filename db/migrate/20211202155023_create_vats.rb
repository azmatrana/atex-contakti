class CreateVats < ActiveRecord::Migration
  def change
    create_table :vats do |t|
      t.integer :vat_percentage, default: 0, unique: :true
      t.references :company, foreign_key: true
      t.timestamps
    end
  end
end
