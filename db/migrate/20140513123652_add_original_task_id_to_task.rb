class AddOriginalTaskIdToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :original_task_id, :integer
  end
end
