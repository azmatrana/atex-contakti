class AddColumnsInSipSettings < ActiveRecord::Migration
  def change
    add_column :users, :is_dnd_active, :boolean, default: false
    add_column :users, :is_transfer_active, :boolean, default: false
    add_column :users, :is_acd_active, :boolean, default: false
    add_column :users, :is_follow_active, :boolean, default: false
  end
end
