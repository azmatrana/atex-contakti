class AddLastSeenTaskToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_seen_tasks, :datetime
  end
end
