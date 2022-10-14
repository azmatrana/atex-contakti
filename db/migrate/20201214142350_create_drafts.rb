class CreateDrafts < ActiveRecord::Migration
  def change
    create_table :drafts do |t|
      t.integer :task_id
      t.text :description, null: false, default: ''
      t.timestamps
    end
  end
end
