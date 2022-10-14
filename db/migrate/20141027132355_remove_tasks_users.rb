class RemoveTasksUsers < ActiveRecord::Migration
  def up
    drop_table :tasks_users
  end
  def down
    create_table :tasks_users, id: false do |t|
      t.integer :task_id
      t.integer :user_id
    end
    ::Task.find_each do |t|
      t.user_ids = t.service_channel.user_ids
    end
  end
end
