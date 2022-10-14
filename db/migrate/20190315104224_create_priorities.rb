class CreatePriorities < ActiveRecord::Migration
  def change
    create_table :priorities do |t|
      t.integer :company_id
      t.integer :tag_id
      t.integer :priority_value

      t.timestamps
    end
  end
end
