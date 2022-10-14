class SwitchUserAndServiceChannelRelations < ActiveRecord::Migration
  def change
    remove_column :service_channels, :user_id, :integer
    add_column :users, :service_channel_id, :integer
  end
end
