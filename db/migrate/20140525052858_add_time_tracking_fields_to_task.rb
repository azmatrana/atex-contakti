class AddTimeTrackingFieldsToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :minutes_spent, :integer, null: false, default: 0
    add_column :tasks, :assigned_to_user_id, :integer
    add_column :tasks, :last_opened_at, :datetime
  end
end
