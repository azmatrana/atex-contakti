class AddGroupIdToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :group_id, :string, null: false, default: ''
  end
end
