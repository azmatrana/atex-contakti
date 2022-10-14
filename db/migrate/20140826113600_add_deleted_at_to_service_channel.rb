class AddDeletedAtToServiceChannel < ActiveRecord::Migration
  def change
    add_column :service_channels, :deleted_at, :datetime
    add_index :service_channels, :deleted_at
    add_column :media_channels, :deleted_at, :datetime
    add_index :media_channels, :deleted_at
    add_column :tasks, :deleted_at, :datetime
    add_index :tasks, :deleted_at
    add_column :messages, :deleted_at, :datetime
    add_index :messages, :deleted_at
  end
end
