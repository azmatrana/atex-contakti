class AddNameCheckForMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :name_check, :boolean, null: false, default: false
  end
end
