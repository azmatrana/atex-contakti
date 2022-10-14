class ChangeMediaChannelTypeColumn < ActiveRecord::Migration
  def up
    change_column :media_channels, :type, :string, limit: 50, null: false, default: ''
  end

  def down
    # do nothing
  end
end
