class AddDeletedAtToPriority < ActiveRecord::Migration
  def change
    add_column :priorities, :deleted_at, :datetime
    add_index :priorities, :deleted_at
  end
end
