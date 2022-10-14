class AddActiveToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :active, :boolean, null: false, default: true
  end
end
