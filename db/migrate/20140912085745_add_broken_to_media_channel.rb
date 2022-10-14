class AddBrokenToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :broken, :boolean, null: false, default: false
  end
end
