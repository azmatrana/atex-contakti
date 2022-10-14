class AddCreatedByUserIdFieldToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :created_by_user_id, :integer
  end
end
