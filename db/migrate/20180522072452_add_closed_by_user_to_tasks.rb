class AddClosedByUserToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :closed_by_user_id, :integer, null: true
  end
end
