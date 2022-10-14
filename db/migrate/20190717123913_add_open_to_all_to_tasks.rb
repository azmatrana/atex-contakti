class AddOpenToAllToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :open_to_all, :boolean, default: false
  end
end
