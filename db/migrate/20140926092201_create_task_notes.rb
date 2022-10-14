class CreateTaskNotes < ActiveRecord::Migration
  def change
    create_table :task_notes do |t|
      t.integer :task_id, null: false
      t.text :body

      t.timestamps
    end
  end
end
