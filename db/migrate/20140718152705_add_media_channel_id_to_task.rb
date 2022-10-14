class AddMediaChannelIdToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :media_channel_id, :integer
  end
end
