class AddSendByUserToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :send_by_user_id, :integer, null: true
  end
end
