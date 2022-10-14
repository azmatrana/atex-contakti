class CreateCustomerNotes < ActiveRecord::Migration
  def change
    create_table :customer_notes do |t|
      t.references :customer, index: true
      t.text :body

      t.timestamps
    end
  end
end
