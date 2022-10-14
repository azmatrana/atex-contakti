class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :first_name, limit: 100, null: false, default: ''
      t.string  :last_name, limit: 250, null: false, default: ''
      t.string  :title, limit: 100, null: false, default: ''
      t.string  :mobile, limit: 100, null: false, default: ''
      t.integer :company_id
      t.timestamps
    end
  end
end
