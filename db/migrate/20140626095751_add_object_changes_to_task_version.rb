class AddObjectChangesToTaskVersion < ActiveRecord::Migration
  def change
    add_column :task_versions, :object_changes, :text
  end
end
