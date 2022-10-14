class RemoveTaskFields < ActiveRecord::Migration
  def up
    remove_column :tasks, :from
    remove_column :tasks, :to
    remove_column :tasks, :title
    remove_column :tasks, :description
    remove_column :tasks, :message_id
    remove_column :tasks, :message_uid
    remove_column :tasks, :in_reply_to_id
    remove_column :tasks, :original_task_id
  end
  def down
    # do nothing
  end
end
