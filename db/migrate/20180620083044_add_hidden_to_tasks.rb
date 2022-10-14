class AddHiddenToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :hidden, :boolean
  end
end
