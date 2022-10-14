class AddMediaChannelTypesToUser < ActiveRecord::Migration
  def change
    add_column :users, :media_channel_types, :text, array: true, default: []
  end
end
