class AddStateFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_online, :boolean, null: false, default: false
    add_column :users, :is_working, :boolean, null: false, default: false
    add_column :users, :started_working_at, :datetime
  end
end
