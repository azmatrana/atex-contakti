class AddMediaChannelTypesToReport < ActiveRecord::Migration
  def change
    add_column :reports, :media_channel_types, :text, array: true, default: []
  end
end
